WITH sales_details AS (
   SELECT
       cs.cs_order_number,
       cs.cs_call_center_sk,
       cs.cs_catalog_page_sk,
       cs.cs_ship_mode_sk,
       cs.cs_promo_sk,
       cs.cs_net_profit,
       cs.cs_net_paid_inc_tax,
       cc.cc_name,
       cc.cc_city,
       cc.cc_class,
       cp.cp_description,
       cp.cp_type,
       sm.sm_type,
       p.p_promo_name,
       p.p_channel_radio
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE regexp_like(p.p_promo_name, '^SAVE[0-9]{2,4}$')
     AND cp.cp_description LIKE '%new%'
     AND sm.sm_type LIKE '%AIR%'
),
agg_sales AS (
   SELECT
       CONCAT(s.cc_name, ' - ', s.cc_city) AS center_full_name,
       s.cc_class,
       SUM(s.cs_net_profit) AS total_profit,
       COUNT(*) AS sales_count,
       SUBSTRING(s.cp_description, 1, 30) AS short_description
   FROM sales_details s
   WHERE EXISTS (
       SELECT 1
       FROM promotion p2
       WHERE p2.p_promo_sk = s.cs_promo_sk
         AND p2.p_channel_radio = 'N'
   )
   GROUP BY
       CONCAT(s.cc_name, ' - ', s.cc_city),
       s.cc_class,
       SUBSTRING(s.cp_description, 1, 30)
)
SELECT
    a.center_full_name,
    a.cc_class,
    a.total_profit,
    CASE WHEN a.total_profit > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
    a.sales_count,
    a.short_description,
    (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_profit_all,
    ROW_NUMBER() OVER (ORDER BY a.total_profit DESC) AS profit_rank
FROM agg_sales a
ORDER BY profit_rank
LIMIT 100
