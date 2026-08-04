WITH base AS (
   SELECT
       cs.cs_order_number,
       cp.cp_type,
       cp.cp_catalog_page_number,
       w.w_country,
       w.w_zip,
       cs.cs_list_price,
       cs.cs_net_paid_inc_tax,
       r.r_reason_desc,
       cd.cd_dep_employed_count,
       hd.hd_vehicle_count,
       wr.wr_return_quantity,
       wr.wr_return_amt
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN web_returns wr
     ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE cp.cp_type = 'monthly'
     AND w.w_country = 'United States'
     AND cs.cs_list_price > 100
     AND cd.cd_dep_employed_count >= 2
     AND r.r_reason_desc LIKE '%damaged%'
),
order_agg AS (
   SELECT
       cs_order_number,
       SUM(cs_net_paid_inc_tax) AS total_sales,
       SUM(wr_return_amt)      AS total_returns,
       COUNT(*)                AS txn_cnt
   FROM base
   GROUP BY cs_order_number
   HAVING SUM(cs_net_paid_inc_tax) > 500
),
high_return AS (
   SELECT
       cs_order_number,
       total_sales,
       total_returns,
       txn_cnt
   FROM order_agg
   WHERE total_returns > 200
)
SELECT
   cs_order_number,
   total_sales,
   total_returns,
   txn_cnt
FROM high_return
WHERE cs_order_number NOT IN (
      SELECT cs_order_number FROM order_agg WHERE total_sales < 1000
)
UNION DISTINCT
SELECT
   cs_order_number,
   total_sales,
   total_returns,
   txn_cnt
FROM high_return
WHERE cs_order_number IN (
      SELECT cs_order_number FROM order_agg
      INTERSECT
      SELECT cs_order_number FROM order_agg WHERE total_returns > 0
)
ORDER BY total_sales DESC
LIMIT 100
