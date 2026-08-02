WITH sales_data AS (
   SELECT
      d.d_year AS order_year,
      p.p_promo_name AS promo_name,
      cs.cs_net_paid AS net_paid,
      cs.cs_quantity AS quantity,
      c.c_customer_id AS customer_id,
      ib.ib_upper_bound AS income_upper,
      cs.cs_order_number AS order_number,
      (
         SELECT COALESCE(SUM(cr2.cr_return_amount), 0)
         FROM catalog_returns cr2
         WHERE cr2.cr_order_number = cs.cs_order_number
      ) AS total_return_amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND d.d_qoy = 1
     AND cd.cd_dep_count > 2
     AND hd.hd_vehicle_count >= 2
     AND ib.ib_lower_bound >= 50000
     AND p.p_discount_active = 'Y'
     AND NOT EXISTS (
         SELECT 1 FROM web_returns wr2
         WHERE wr2.wr_order_number = cs.cs_order_number
     )
),
returns_data AS (
   SELECT
      d.d_year AS order_year,
      p.p_promo_name AS promo_name,
      cs.cs_net_paid AS net_paid,
      cr.cr_return_quantity AS quantity,
      c.c_customer_id AS customer_id,
      ib.ib_upper_bound AS income_upper,
      cs.cs_order_number AS order_number,
      (
         SELECT COALESCE(SUM(cr2.cr_return_amount), 0)
         FROM catalog_returns cr2
         WHERE cr2.cr_order_number = cs.cs_order_number
      ) AS total_return_amount
   FROM catalog_returns cr
   JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
     AND d.d_current_month = 'Y'
     AND cd.cd_dep_employed_count >= 1
     AND hd.hd_dep_count <= 5
     AND ib.ib_upper_bound <= 150000
     AND p.p_discount_active = 'N'
     AND NOT EXISTS (
         SELECT 1 FROM catalog_sales cs2
         WHERE cs2.cs_order_number = cr.cr_order_number
           AND cs2.cs_item_sk = cr.cr_item_sk
     )
)
SELECT
   order_year,
   promo_name,
   SUM(net_paid) AS total_net_paid,
   AVG(net_paid) AS avg_net_paid,
   SUM(quantity) AS total_quantity,
   COUNT(DISTINCT customer_id) AS distinct_customers,
   MAX(income_upper) AS max_income_upper,
   SUM(total_return_amount) AS total_return_amount_sum
FROM (
   SELECT * FROM sales_data
   UNION ALL
   SELECT * FROM returns_data
) combined
GROUP BY order_year, promo_name
ORDER BY total_net_paid DESC
LIMIT 100
