WITH sales_base AS (
    SELECT
        s.s_store_name,
        d.d_year,
        sm.sm_type,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number,
        i.inv_quantity_on_hand,
        p.p_discount_active,
        ca.ca_state,
        w.web_name,
        s.s_market_id,
        l.max_qty_on_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory i TABLESAMPLE BERNOULLI (10) ON i.inv_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT max(i2.inv_quantity_on_hand) AS max_qty_on_date
        FROM inventory i2
        WHERE i2.inv_date_sk = d.d_date_sk
    ) AS l
    WHERE d.d_year = 2002
      AND s.s_market_id = 7
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
),
unioned AS (
    SELECT
        s_store_name,
        d_year,
        CASE WHEN sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_category,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS order_cnt,
        AVG(ss_ext_discount_amt) AS avg_discount,
        max_qty_on_date
    FROM sales_base
    GROUP BY s_store_name, d_year, CASE WHEN sm_type = 'AIR' THEN 'Air' ELSE 'Other' END, max_qty_on_date

    UNION

    SELECT
        s_store_name,
        d_year,
        CASE WHEN sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_category,
        SUM(ss_net_paid) * 0.9 AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS order_cnt,
        AVG(ss_ext_discount_amt) AS avg_discount,
        max_qty_on_date
    FROM sales_base
    WHERE s_market_id = 10
    GROUP BY s_store_name, d_year, CASE WHEN sm_type = 'AIR' THEN 'Air' ELSE 'Other' END, max_qty_on_date
),
final_set AS (
    SELECT * FROM unioned
    EXCEPT
    SELECT * FROM unioned WHERE ship_category = 'Other' AND total_net_paid < 1000
)
SELECT
    s_store_name,
    d_year,
    ship_category,
    total_net_paid,
    order_cnt,
    avg_discount,
    max_qty_on_date
FROM final_set
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
