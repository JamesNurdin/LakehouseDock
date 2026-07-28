WITH cs_agg AS (
   SELECT
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_ship_mode_sk,
      cs_warehouse_sk,
      cs_bill_hdemo_sk,
      SUM(cs_ext_sales_price)        AS total_sales,
      SUM(cs_net_profit)             AS total_profit,
      COUNT(*)                       AS order_cnt
   FROM catalog_sales
   WHERE cs_quantity > 5
     AND cs_ext_sales_price > 100
   GROUP BY cs_call_center_sk, cs_catalog_page_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_bill_hdemo_sk
),
ssa AS (
   SELECT
      ss_sold_time_sk,
      ss_hdemo_sk,
      SUM(ss_ext_sales_price) AS store_sales,
      SUM(ss_net_profit)      AS store_profit
   FROM store_sales
   WHERE ss_quantity > 3
   GROUP BY ss_sold_time_sk, ss_hdemo_sk
),
wr_agg AS (
   SELECT
      wr_returned_time_sk,
      wr_refunded_hdemo_sk,
      wr_web_page_sk,
      SUM(wr_return_amt) AS total_return,
      COUNT(*)           AS return_cnt
   FROM web_returns
   WHERE wr_return_amt > 0
     AND wr_return_tax > 5
   GROUP BY wr_returned_time_sk, wr_refunded_hdemo_sk, wr_web_page_sk
)
SELECT
   cc.cc_name,
   cc.cc_state,
   cp.cp_catalog_number,
   sm.sm_type,
   w.w_warehouse_name,
   hd.hd_vehicle_count,
   td.t_hour,
   SUM(cs_agg.total_sales)        AS sum_sales,
   SUM(cs_agg.total_profit)       AS sum_profit,
   SUM(ssa.store_sales)           AS sum_store_sales,
   SUM(ssa.store_profit)          AS sum_store_profit,
   SUM(wr_agg.total_return)       AS sum_returns,
   SUM(wr_agg.return_cnt)         AS total_return_cnt,
   COUNT(DISTINCT cp.cp_catalog_number) AS distinct_catalogs,
   ROW_NUMBER() OVER (PARTITION BY cc.cc_company ORDER BY SUM(cs_agg.total_sales) DESC) AS sales_rank
FROM cs_agg
JOIN call_center cc       ON cc.cc_call_center_sk = cs_agg.cs_call_center_sk
JOIN catalog_page cp      ON cp.cp_catalog_page_sk = cs_agg.cs_catalog_page_sk
JOIN ship_mode sm         ON sm.sm_ship_mode_sk = cs_agg.cs_ship_mode_sk
JOIN warehouse w          ON w.w_warehouse_sk = cs_agg.cs_warehouse_sk
JOIN household_demographics hd ON hd.hd_demo_sk = cs_agg.cs_bill_hdemo_sk
JOIN ssa                  ON ssa.ss_hdemo_sk = hd.hd_demo_sk
JOIN time_dim td          ON td.t_time_sk = ssa.ss_sold_time_sk
JOIN wr_agg               ON wr_agg.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp          ON wp.wp_web_page_sk = wr_agg.wr_web_page_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND wp.wp_type = 'general'
  AND wp.wp_rec_start_date <= DATE '2005-12-31'
  AND hd.hd_vehicle_count > 2
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
   cc.cc_name,
   cc.cc_state,
   cp.cp_catalog_number,
   sm.sm_type,
   w.w_warehouse_name,
   hd.hd_vehicle_count,
   td.t_hour,
   cc.cc_company
ORDER BY sum_sales DESC
LIMIT 100
