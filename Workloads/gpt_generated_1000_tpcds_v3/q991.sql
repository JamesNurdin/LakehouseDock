WITH agg_store_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss_ticket_number) AS distinct_store_orders
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_store_sk, ss_promo_sk, ss_customer_sk, ss_cdemo_sk
)
SELECT
    d_ss.d_year,
    s.s_store_name,
    p.p_promo_name,
    CASE WHEN cd_ss.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
    COUNT(DISTINCT c_ss.c_customer_id) AS distinct_customers,
    SUM(agg_store_sales.store_net_paid) AS total_store_net_paid,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(agg_store_sales.store_net_paid + cs.cs_net_paid + ws.ws_net_paid - cr.cr_net_loss) AS net_total,
    (SELECT SUM(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_sk = p.p_promo_sk) AS total_promo_cost,
    SUM(agg_store_sales.distinct_store_orders) AS total_distinct_store_orders
FROM agg_store_sales
JOIN date_dim d_ss
    ON agg_store_sales.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t
    ON agg_store_sales.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON agg_store_sales.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON agg_store_sales.ss_promo_sk = p.p_promo_sk
JOIN customer c_ss
    ON agg_store_sales.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss
    ON agg_store_sales.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_ss.d_date_sk
    AND cs.cs_bill_customer_sk = c_ss.c_customer_sk
    AND cs.cs_bill_cdemo_sk = cd_ss.cd_demo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ss.d_date_sk
    AND ws.ws_bill_customer_sk = c_ss.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd_ss.cd_demo_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    d_ss.d_year = 2001
    AND s.s_country = 'United States'
    AND cd_ss.cd_gender = 'M'
    AND cp.cp_catalog_number IN (3, 13, 14)
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc LIKE '%damaged%'
    AND cs.cs_promo_sk = p.p_promo_sk
GROUP BY
    d_ss.d_year,
    s.s_store_name,
    p.p_promo_name,
    cd_ss.cd_gender,
    p.p_promo_sk
HAVING
    SUM(agg_store_sales.store_net_paid) > 10000
ORDER BY net_total DESC
LIMIT 100
