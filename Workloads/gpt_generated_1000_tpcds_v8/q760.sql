WITH sampled_page AS (
    SELECT *
    FROM web_page
    TABLESAMPLE BERNOULLI (10)
),
raw_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year,
        p.p_promo_id,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_sales_price,
        ca.ca_city,
        r.r_reason_desc,
        i.inv_quantity_on_hand,
        w.w_city            AS warehouse_city,
        ws.ws_net_paid      AS web_sales_net_paid,
        we.web_name
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN sampled_page sp
        ON ws.ws_web_page_sk = sp.wp_web_page_sk
    LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND c.c_customer_sk NOT IN (
            SELECT sr_customer_sk FROM store_returns
        )
      AND s.s_store_sk IN (
            SELECT ss_store_sk FROM store_sales
            INTERSECT
            SELECT sr_store_sk FROM store_returns
        )
)
SELECT
    rd.c_customer_sk,
    rd.c_first_name,
    rd.c_last_name,
    rd.s_store_name,
    rd.s_state,
    SUM(rd.ss_net_paid)                         AS total_store_sales,
    SUM(rd.ss_ext_sales_price)                  AS total_extended_sales,
    CASE WHEN SUM(rd.ss_quantity) > 10 THEN 'HIGH' ELSE 'LOW' END AS quantity_flag,
    COUNT(DISTINCT rd.p_promo_id)               AS promo_count,
    AVG(rd.inv_quantity_on_hand)                AS avg_inventory,
    (
        SELECT SUM(ws2.ws_net_paid)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = rd.c_customer_sk
    )                                            AS total_web_sales_for_customer,
    RANK() OVER (PARTITION BY rd.s_state ORDER BY SUM(rd.ss_net_paid) DESC) AS sales_rank,
    rd.ca_city,
    rd.r_reason_desc,
    rd.warehouse_city,
    rd.web_name
FROM raw_data rd
GROUP BY
    rd.c_customer_sk,
    rd.c_first_name,
    rd.c_last_name,
    rd.s_store_name,
    rd.s_state,
    rd.ca_city,
    rd.r_reason_desc,
    rd.warehouse_city,
    rd.web_name
HAVING SUM(rd.ss_net_paid) > 1000
ORDER BY total_store_sales DESC
LIMIT 100
