WITH
sales_union AS (
   SELECT
     cs_order_number AS order_number,
     cs_sold_date_sk AS sold_date_sk,
     cs_sold_time_sk AS sold_time_sk,
     cs_item_sk AS item_sk,
     cs_bill_customer_sk AS customer_sk,
     cs_call_center_sk AS call_center_sk,
     cs_promo_sk AS promo_sk,
     cs_quantity AS quantity,
     cs_net_paid AS net_paid,
     cs_net_paid_inc_tax AS net_paid_inc_tax,
     cs_net_profit AS net_profit,
     cs_coupon_amt AS coupon_amt,
     cs_ext_discount_amt AS ext_discount_amt,
     cs_ext_sales_price AS ext_sales_price,
     'catalog' AS source
   FROM catalog_sales
   UNION ALL
   SELECT
     ss_ticket_number AS order_number,
     ss_sold_date_sk AS sold_date_sk,
     ss_sold_time_sk AS sold_time_sk,
     ss_item_sk AS item_sk,
     ss_customer_sk AS customer_sk,
     NULL AS call_center_sk,
     ss_promo_sk AS promo_sk,
     ss_quantity AS quantity,
     ss_net_paid AS net_paid,
     ss_net_paid_inc_tax AS net_paid_inc_tax,
     ss_net_profit AS net_profit,
     ss_coupon_amt AS coupon_amt,
     ss_ext_discount_amt AS ext_discount_amt,
     ss_ext_sales_price AS ext_sales_price,
     'store' AS source
   FROM store_sales
   UNION ALL
   SELECT
     ws_order_number AS order_number,
     ws_sold_date_sk AS sold_date_sk,
     ws_sold_time_sk AS sold_time_sk,
     ws_item_sk AS item_sk,
     ws_bill_customer_sk AS customer_sk,
     NULL AS call_center_sk,
     ws_promo_sk AS promo_sk,
     ws_quantity AS quantity,
     ws_net_paid AS net_paid,
     ws_net_paid_inc_tax AS net_paid_inc_tax,
     ws_net_profit AS net_profit,
     ws_coupon_amt AS coupon_amt,
     ws_ext_discount_amt AS ext_discount_amt,
     ws_ext_sales_price AS ext_sales_price,
     'web' AS source
   FROM web_sales
),
ranked_sales AS (
   SELECT
     su.*,
     ROW_NUMBER() OVER (PARTITION BY su.customer_sk, su.source ORDER BY su.net_profit DESC NULLS LAST, su.order_number) AS profit_rank,
     SUM(su.ext_sales_price) OVER (PARTITION BY su.customer_sk, su.source) AS total_sales_by_cust_source,
     AVG(su.ext_discount_amt) OVER (PARTITION BY su.customer_sk, su.source) AS avg_discount_by_cust_source,
     LAG(su.net_paid) OVER (PARTITION BY su.customer_sk, su.source ORDER BY su.sold_date_sk, su.sold_time_sk) AS lag_net_paid,
     LEAD(su.net_paid) OVER (PARTITION BY su.customer_sk, su.source ORDER BY su.sold_date_sk, su.sold_time_sk) AS lead_net_paid
   FROM sales_union su
),
cust_sales AS (
   SELECT
     rs.*,
     c.c_customer_id,
     c.c_first_name,
     c.c_last_name,
     COALESCE(c.c_preferred_cust_flag, 'N') AS preferred_flag,
     d.d_date,
     d.d_year,
     d.d_month_seq,
     d.d_day_name,
     CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'Regular' END AS day_type,
     CASE
       WHEN rs.lag_net_paid IS NULL THEN 'FirstSale'
       WHEN rs.net_paid > rs.lag_net_paid THEN 'Increase'
       ELSE 'Decrease'
     END AS net_paid_trend,
     CONCAT_WS('_', rs.source, COALESCE(c.c_last_name, 'UNKNOWN'), CAST(rs.profit_rank AS VARCHAR)) AS composite_key,
     rs.net_profit / NULLIF(rs.net_paid_inc_tax, 0) AS profit_to_paid_ratio,
     (SELECT MAX(inner_rs.net_profit) FROM ranked_sales inner_rs WHERE inner_rs.customer_sk = rs.customer_sk) AS customer_max_profit,
     (SELECT MIN(d2.d_date) FROM date_dim d2 JOIN ranked_sales rs2 ON rs2.sold_date_sk = d2.d_date_sk WHERE rs2.customer_sk = rs.customer_sk) AS customer_first_sale_date,
     CASE
       WHEN EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_order_number = rs.order_number)
         OR EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_ticket_number = rs.order_number)
         OR EXISTS (SELECT 1 FROM web_returns wr WHERE wr.wr_order_number = rs.order_number)
       THEN 1 ELSE 0 END AS has_return,
     AVG(rs.net_paid) OVER (PARTITION BY rs.customer_sk ORDER BY rs.sold_date_sk, rs.sold_time_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_net_paid_3,
     CASE WHEN rs.coupon_amt IS NULL THEN rs.quantity ELSE rs.quantity * 0.5 END AS adjusted_quantity,
     CASE WHEN EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = rs.item_sk AND rs.sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) THEN 1 ELSE 0 END AS promo_active,
     cc.cc_name AS call_center_name,
     CASE WHEN rs.source IS NOT DISTINCT FROM 'catalog' THEN 1 ELSE 0 END AS is_source_catalog_nullsafe,
     CASE WHEN rs.source IS NOT DISTINCT FROM 'catalog' THEN 'CATA' ELSE 'OTHER' END AS source_nullsafe_flag
   FROM ranked_sales rs
   LEFT JOIN customer c ON rs.customer_sk = c.c_customer_sk
   LEFT JOIN date_dim d ON rs.sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON rs.call_center_sk = cc.cc_call_center_sk
)
SELECT *
FROM cust_sales
WHERE profit_rank <= 3
UNION ALL
SELECT *
FROM cust_sales
WHERE has_return = 1 AND profit_rank > 3
EXCEPT
SELECT *
FROM cust_sales
WHERE day_type = 'Holiday'
ORDER BY composite_key, profit_rank
