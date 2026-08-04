WITH base AS (
   SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      ss.ss_net_paid,
      c.c_customer_id,
      c.c_email_address,
      cc.cc_name,
      cp.cp_department,
      w.w_warehouse_name,
      p.p_promo_name,
      td.t_hour,
      wp.wp_web_page_id,
      wp.wp_autogen_flag,
      r.r_reason_desc,
      cr.cr_return_amount
   FROM catalog_sales cs
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim td
     ON cs.cs_sold_time_sk = td.t_time_sk
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN web_page wp
     ON wp.wp_customer_sk = c.c_customer_sk
   JOIN store_sales ss
     ON ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_sold_time_sk = td.t_time_sk
    AND ss.ss_promo_sk = p.p_promo_sk
   WHERE cc.cc_company = 1
     AND p.p_discount_active = 'Y'
     AND td.t_hour BETWEEN 9 AND 17
     AND wp.wp_autogen_flag = 'N'
     AND c.c_email_address LIKE '%@i.org'
),
intersect_orders AS (
   SELECT cs_order_number FROM base WHERE cs_ext_sales_price > 2000
   INTERSECT
   SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount = 0
)
SELECT
   base.cc_name,
   base.cp_department,
   base.t_hour,
   COUNT(DISTINCT base.cs_order_number) AS num_orders,
   SUM(base.cs_ext_sales_price) AS total_sales,
   AVG(base.ss_net_paid) AS avg_store_net_paid,
   SUM(base.cs_net_profit) AS total_profit
FROM base
JOIN intersect_orders io
  ON base.cs_order_number = io.cs_order_number
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = base.cs_order_number
      AND cr2.cr_return_amount > 0
)
GROUP BY base.cc_name, base.cp_department, base.t_hour
HAVING SUM(base.cs_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
