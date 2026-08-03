WITH cs_base AS (
   SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      d.d_year,
      cs.cs_bill_customer_sk,
      cs.cs_net_paid,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      i.i_item_id,
      i.i_units,
      CASE WHEN i.i_units = 'Dozen' THEN 'Bulk' ELSE 'Regular' END AS unit_type,
      ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS metrics_arr
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND cs.cs_bill_customer_sk NOT IN (SELECT DISTINCT wr_refunded_customer_sk FROM web_returns)
),
cs_unnest AS (
   SELECT
      cs_order_number,
      cs_sold_date_sk,
      d_year,
      cs_bill_customer_sk,
      cs_net_paid,
      cs_quantity,
      cs_ext_sales_price,
      i_item_id,
      i_units,
      unit_type,
      metric,
      ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cs_net_paid DESC) AS rn_year
   FROM cs_base
   CROSS JOIN UNNEST(cs_base.metrics_arr) AS t(metric)
),
cs_top AS (
   SELECT * FROM cs_unnest WHERE rn_year <= 5
),
ss_base AS (
   SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      d.d_year,
      ss.ss_customer_sk,
      ss.ss_net_paid,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      i.i_item_id,
      i.i_units,
      CASE WHEN i.i_units = 'Dozen' THEN 'Bulk' ELSE 'Regular' END AS unit_type,
      ARRAY[ss.ss_quantity, ss.ss_ext_sales_price] AS metrics_arr
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND ss.ss_customer_sk NOT IN (SELECT DISTINCT wr_refunded_customer_sk FROM web_returns)
),
ss_unnest AS (
   SELECT
      ss_ticket_number,
      ss_sold_date_sk,
      d_year,
      ss_customer_sk,
      ss_net_paid,
      ss_quantity,
      ss_ext_sales_price,
      i_item_id,
      i_units,
      unit_type,
      metric,
      ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY ss_net_paid DESC) AS rn_year
   FROM ss_base
   CROSS JOIN UNNEST(ss_base.metrics_arr) AS t(metric)
),
ss_top AS (
   SELECT * FROM ss_unnest WHERE rn_year <= 5
)
SELECT
   order_id,
   date_sk,
   d_year,
   customer_sk,
   net_paid,
   quantity,
   ext_sales_price,
   i_item_id,
   i_units,
   unit_type,
   metric,
   rn_year,
   ROW_NUMBER() OVER () AS final_global_rn,
   (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
FROM (
   SELECT
      cs_order_number AS order_id,
      cs_sold_date_sk AS date_sk,
      d_year,
      cs_bill_customer_sk AS customer_sk,
      cs_net_paid AS net_paid,
      cs_quantity AS quantity,
      cs_ext_sales_price AS ext_sales_price,
      i_item_id,
      i_units,
      unit_type,
      metric,
      rn_year
   FROM cs_top

   UNION ALL

   SELECT
      ss_ticket_number AS order_id,
      ss_sold_date_sk AS date_sk,
      d_year,
      ss_customer_sk AS customer_sk,
      ss_net_paid AS net_paid,
      ss_quantity AS quantity,
      ss_ext_sales_price AS ext_sales_price,
      i_item_id,
      i_units,
      unit_type,
      metric,
      rn_year
   FROM ss_top
) AS combined
ORDER BY net_paid DESC
LIMIT 100
