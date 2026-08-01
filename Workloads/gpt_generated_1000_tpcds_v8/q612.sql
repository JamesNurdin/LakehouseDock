WITH
    -- Re‑use CUSTOMER_ADDRESS under different aliases for billing, shipping, web‑sales billing and web‑sales shipping
    ca_bill AS (SELECT * FROM customer_address),
    ca_ship AS (SELECT * FROM customer_address),
    ca_ws_bill AS (SELECT * FROM customer_address),
    ca_ws_ship AS (SELECT * FROM customer_address),
    ca_ss_addr AS (SELECT * FROM customer_address),
    -- DATE_DIM used twice (sold date and ship date)
    d_sold AS (SELECT * FROM date_dim),
    d_ship AS (SELECT * FROM date_dim),
    -- TIME_DIM for the time of the sale
    t AS (SELECT * FROM time_dim),
    -- Join all nine tables together
    joined AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_call_center_sk,
            cs.cs_bill_addr_sk AS cs_bill_addr_sk,
            cs.cs_ship_addr_sk AS cs_ship_addr_sk,
            cs.cs_item_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            ws.ws_sold_date_sk,
            ws.ws_ship_date_sk,
            ws.ws_web_page_sk,
            ws.ws_web_site_sk,
            ws.ws_bill_addr_sk,
            ws.ws_ship_addr_sk,
            ws.ws_net_paid,
            ss.ss_sold_date_sk,
            ss.ss_addr_sk AS ss_addr_sk,
            ss.ss_store_sk,
            ss.ss_net_paid,
            cc.cc_name,
            wp.wp_url,
            wsit.web_name,
            d_sold.d_year,
            t.t_shift,
            ca_bill.ca_state AS bill_state,
            ca_ship.ca_state AS ship_state,
            ca_ws_bill.ca_state AS ws_bill_state,
            ca_ws_ship.ca_state AS ws_ship_state,
            ca_ss_addr.ca_state AS ss_state
        FROM catalog_sales cs
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsit
            ON ws.ws_web_site_sk = wsit.web_site_sk
        JOIN d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN t
            ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN ca_bill
            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN ca_ship
            ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
        JOIN ca_ws_bill
            ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
        JOIN ca_ws_ship
            ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
        JOIN ca_ss_addr
            ON ss.ss_addr_sk = ca_ss_addr.ca_address_sk
    ),
    -- Sets of addresses for INTERSECT
    addr_set1 AS (
        SELECT ca_address_sk FROM customer_address WHERE ca_state = 'CA'
    ),
    addr_set2 AS (
        SELECT ca_address_sk FROM customer_address WHERE ca_country = 'USA'
    ),
    intersected_addrs AS (
        SELECT ca_address_sk FROM addr_set1 INTERSECT SELECT ca_address_sk FROM addr_set2
    ),
    -- Keep only rows whose billing address is in the intersected set
    filtered AS (
        SELECT j.* FROM joined j
        WHERE j.cs_bill_addr_sk IN (SELECT ca_address_sk FROM intersected_addrs)
    ),
    -- Anti‑join: exclude rows that have a closed web site on the same ship‑date key
    anti AS (
        SELECT f.* FROM filtered f
        WHERE NOT EXISTS (
            SELECT 1 FROM web_site ws2
            WHERE ws2.web_site_sk = f.ws_web_site_sk
              AND ws2.web_close_date_sk IS NOT NULL
              AND ws2.web_close_date_sk = f.cs_ship_date_sk
        )
    ),
    -- First aggregation
    aggregated AS (
        SELECT
            d_year,
            bill_state,
            SUM(cs_net_paid) AS total_cs_paid,
            SUM(ws_net_paid) AS total_ws_paid,
            SUM(ss_net_paid) AS total_ss_paid,
            COUNT(*) AS txn_count,
            (
                SELECT COUNT(*)
                FROM store_sales ss2
                JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
                WHERE d2.d_year = anti.d_year
            ) AS ss_year_count
        FROM anti
        GROUP BY d_year, bill_state
    ),
    -- Second aggregation with a different grouping key and an extra filter (used for UNION)
    aggregated2 AS (
        SELECT
            d_year,
            ship_state AS bill_state,
            SUM(cs_net_paid) AS total_cs_paid,
            SUM(ws_net_paid) AS total_ws_paid,
            SUM(ss_net_paid) AS total_ss_paid,
            COUNT(*) AS txn_count,
            (
                SELECT COUNT(*)
                FROM store_sales ss2
                JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
                WHERE d2.d_year = anti.d_year
            ) AS ss_year_count
        FROM anti
        WHERE t_shift = 'first'
        GROUP BY d_year, ship_state
    ),
    -- UNION DISTINCT of the two aggregates
    unioned AS (
        SELECT * FROM aggregated
        UNION DISTINCT
        SELECT * FROM aggregated2
    ),
    -- Apply window functions on the unioned result
    final AS (
        SELECT
            u.d_year,
            u.bill_state,
            u.total_cs_paid,
            u.total_ws_paid,
            u.total_ss_paid,
            u.txn_count,
            u.ss_year_count,
            RANK() OVER (PARTITION BY u.d_year ORDER BY u.total_cs_paid DESC) AS rank_by_cs,
            SUM(u.total_cs_paid) OVER (PARTITION BY u.d_year) AS sum_cs_year,
            SUM(u.txn_count) OVER (PARTITION BY u.d_year ORDER BY u.bill_state ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_txn_by_state
        FROM unioned u
    )
SELECT *
FROM final
ORDER BY d_year DESC, rank_by_cs
LIMIT 100
