SELECT *
FROM (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       p.p_promo_name,
       SUM(cs.cs_ext_sales_price) AS total_ext_sales,
       AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
       COUNT(*) AS order_cnt,
       MIN(cs.cs_net_paid) AS min_net_paid,
       MAX(cs.cs_net_paid) AS max_net_paid
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_ext_list_price > 5000
     AND cs.cs_quantity BETWEEN 1 AND 5
     AND w.w_state = 'CA'
     AND w.w_gmt_offset = -5.00
     AND p.p_channel_dmail = 'Y'
     AND p.p_end_date_sk BETWEEN 2450150 AND 2450592
   GROUP BY w.w_warehouse_id, w.w_warehouse_name, p.p_promo_name
   UNION ALL
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       p.p_promo_name,
       SUM(cs.cs_ext_sales_price) AS total_ext_sales,
       AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
       COUNT(*) AS order_cnt,
       MIN(cs.cs_net_paid) AS min_net_paid,
       MAX(cs.cs_net_paid) AS max_net_paid
   FROM catalog_sales cs
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_ext_list_price < 3000
     AND cs.cs_quantity >= 10
     AND w.w_city = 'New York'
     AND w.w_gmt_offset = -5.00
     AND p.p_channel_email = 'Y'
     AND p.p_end_date_sk >= 2450904
   GROUP BY w.w_warehouse_id, w.w_warehouse_name, p.p_promo_name
) combined
ORDER BY total_ext_sales DESC
LIMIT 100
