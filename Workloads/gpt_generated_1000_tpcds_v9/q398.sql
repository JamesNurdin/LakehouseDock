/*
Goal: Analyze total net sales, extended sales price and returns by store, item category and year, applying promotion discounts, filtering out customers who ever had a return (anti‑join), showing only items sold through both store and catalog channels (INTERSECT), and providing subtotal rows with GROUPING SETS. The query joins all 15 TPC‑DS tables, reuses date_dim and item under multiple aliases, includes a LEFT OUTER JOIN, and limits the result to the top 100 rows.
*/
WITH intersect_items AS (
    SELECT ss.ss_item_sk AS i_item_sk
    FROM store_sales ss
    INTERSECT
    SELECT cs.cs_item_sk AS i_item_sk
    FROM catalog_sales cs
)
SELECT
    s.s_store_name,
    i_sales.i_category,
    d_sales.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(CASE WHEN p_ss.p_discount_active = 'Y' THEN ss.ss_net_paid * 0.9 ELSE ss.ss_net_paid END) AS net_paid_discounted
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN intersect_items ii ON ss.ss_item_sk = ii.i_item_sk
JOIN item i_sales ON ss.ss_item_sk = i_sales.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
LEFT JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
LEFT JOIN call_center cc2 ON cs.cs_call_center_sk = cc2.cc_call_center_sk
LEFT JOIN item i_promo ON p_ss.p_item_sk = i_promo.i_item_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_returns sr_excl WHERE sr_excl.sr_customer_sk = c.c_customer_sk
)
GROUP BY GROUPING SETS (
    (s.s_store_name, i_sales.i_category, d_sales.d_year),
    (s.s_store_name, i_sales.i_category),
    (s.s_store_name),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
