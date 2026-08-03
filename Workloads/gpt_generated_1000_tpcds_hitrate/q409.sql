WITH discount_bins AS (
   SELECT * FROM (VALUES
       ('Low', 0, 1000),
       ('Medium', 1000, 5000),
       ('High', 5000, 100000)
   ) AS t(bin_name, min_amt, max_amt)
)
SELECT
   cp.cp_department,
   t.t_sub_shift,
   p.p_channel_details,
   db.bin_name,
   COUNT(*) AS order_cnt,
   SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
   AVG(cs.cs_net_paid_inc_tax) AS avg_net_paid,
   MIN(cs.cs_net_paid_inc_tax) AS min_net_paid,
   MAX(cs.cs_net_paid_inc_tax) AS max_net_paid,
   SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt ELSE 0 END) AS total_discount
FROM
   catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   CROSS JOIN discount_bins db
WHERE
   cs.cs_net_paid_inc_tax > 1000
   AND cs.cs_quantity BETWEEN 1 AND 5
   AND cp.cp_department = 'Electronics'
   AND p.p_purpose = 'Unknown'
   AND t.t_hour IN (8, 12, 13)
   AND cs.cs_item_sk IN (SELECT p_item_sk FROM promotion WHERE p_response_target = 1)
   AND cs.cs_ext_discount_amt BETWEEN db.min_amt AND db.max_amt
GROUP BY ROLLUP (cp.cp_department, t.t_sub_shift, p.p_channel_details, db.bin_name)
ORDER BY total_net_paid DESC
LIMIT 100
