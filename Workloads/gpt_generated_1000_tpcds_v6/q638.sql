WITH sales_agg AS (
   SELECT
       sm.sm_ship_mode_id,
       sm.sm_code,
       sm.sm_contract,
       d.d_year,
       SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
       COUNT(*) AS sales_count,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
     AND cs.cs_net_paid_inc_tax > 2000
     AND cs.cs_coupon_amt < 500
     AND sm.sm_code = 'AIR'
     AND sm.sm_contract = 'HVDFCcQ'
     AND inv.inv_quantity_on_hand > 0
     AND wr.wr_return_quantity > 0
   GROUP BY sm.sm_ship_mode_id, sm.sm_code, sm.sm_contract, d.d_year
),
second_agg AS (
   SELECT
       sm.sm_ship_mode_id,
       sm.sm_code,
       sm.sm_contract,
       d.d_year,
       SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
       COUNT(*) AS sales_count,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
   JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
     AND cs.cs_net_paid_inc_tax > 2000
     AND cs.cs_coupon_amt < 500
     AND sm.sm_code = 'AIR'
     AND sm.sm_contract = 'YvxVaJI10'
     AND inv.inv_quantity_on_hand > 0
     AND wr.wr_return_quantity > 0
   GROUP BY sm.sm_ship_mode_id, sm.sm_code, sm.sm_contract, d.d_year
)
SELECT
   ship_mode_id,
   ship_code,
   contract,
   year,
   SUM(total_net_paid) AS sum_net_paid,
   SUM(sales_count) AS sum_sales,
   SUM(total_quantity) AS sum_quantity,
   SUM(total_net_paid) / NULLIF(SUM(sales_count), 0) AS avg_net_paid_per_sale
FROM (
   SELECT sm_ship_mode_id AS ship_mode_id,
          sm_code AS ship_code,
          sm_contract AS contract,
          d_year AS year,
          total_net_paid,
          sales_count,
          total_quantity
   FROM sales_agg
   UNION ALL
   SELECT sm_ship_mode_id,
          sm_code,
          sm_contract,
          d_year,
          total_net_paid,
          sales_count,
          total_quantity
   FROM second_agg
) AS combined
WHERE total_quantity > 1000
GROUP BY ship_mode_id, ship_code, contract, year
HAVING SUM(total_net_paid) / NULLIF(SUM(sales_count), 0) > 5000
ORDER BY year DESC, sum_net_paid DESC
