WITH sampled_sales AS (
   SELECT *
   FROM store_sales
   TABLESAMPLE BERNOULLI (10)
),

sales_part AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_sold_time_sk,
       ss.ss_item_sk,
       ss.ss_quantity,
       ss.ss_net_paid,
       ss.ss_net_profit,
       d.d_year,
       i.i_item_id,
       i.i_color,
       cd.cd_gender,
       hd.hd_income_band_sk,
       t.t_hour
   FROM sampled_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
),

catalog_part AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_returned_date_sk,
       cr.cr_item_sk,
       d.d_year AS cr_year,
       i.i_color AS cr_color,
       cc.cc_name,
       cp.cp_type,
       sm.sm_contract
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
),

web_part AS (
   SELECT
       wr.wr_order_number,
       wr.wr_return_amt,
       wr.wr_return_quantity,
       wr.wr_returned_date_sk,
       wr.wr_item_sk,
       d.d_year AS wr_year,
       i.i_color AS wr_color,
       ws.web_name,
       ws.web_market_manager
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
),

returns_combined AS (
   SELECT
       cp.cr_order_number,
       cp.cr_return_amount,
       cp.cr_return_quantity,
       cp.cr_returned_date_sk,
       cp.cr_item_sk,
       cp.cr_year,
       cp.cr_color,
       cp.cc_name,
       cp.cp_type,
       cp.sm_contract,
       wp.wr_order_number,
       wp.wr_return_amt,
       wp.wr_return_quantity,
       wp.wr_returned_date_sk,
       wp.wr_item_sk,
       wp.wr_year,
       wp.wr_color,
       wp.web_name,
       wp.web_market_manager
   FROM catalog_part cp
   FULL OUTER JOIN web_part wp
     ON cp.cr_item_sk = wp.wr_item_sk
    AND cp.cr_returned_date_sk = wp.wr_returned_date_sk
),

excluded_orders AS (
   SELECT cr_order_number
   FROM catalog_part
   EXCEPT
   SELECT wr_order_number
   FROM web_part
),

final_agg AS (
   SELECT
       COALESCE(rc.cr_year, rc.wr_year, sp.d_year) AS year,
       COALESCE(rc.cr_color, rc.wr_color, sp.i_color) AS color,
       COUNT(DISTINCT COALESCE(rc.cr_order_number, rc.wr_order_number, sp.ss_sold_date_sk)) AS distinct_orders,
       SUM(COALESCE(rc.cr_return_amount, 0) + COALESCE(rc.wr_return_amt, 0) + COALESCE(sp.ss_net_paid, 0)) AS total_amount,
       AVG(COALESCE(rc.cr_return_quantity, 0) + COALESCE(rc.wr_return_quantity, 0) + COALESCE(sp.ss_quantity, 0)) AS avg_quantity,
       MIN(COALESCE(rc.sm_contract, '')) AS min_contract,
       MAX(COALESCE(rc.cc_name, rc.web_name, '')) AS max_name,
       ROW_NUMBER() OVER (ORDER BY COALESCE(rc.cr_year, rc.wr_year, sp.d_year) DESC) AS row_num
   FROM returns_combined rc
   FULL OUTER JOIN sales_part sp
     ON rc.cr_item_sk = sp.ss_item_sk
    AND rc.cr_returned_date_sk = sp.ss_sold_date_sk
   WHERE COALESCE(rc.cr_year, rc.wr_year, sp.d_year) = 2001
     AND COALESCE(rc.cr_color, rc.wr_color, sp.i_color) = 'Red'
     AND COALESCE(rc.sm_contract, 'uukTktPYycct8') = 'uukTktPYycct8'
   GROUP BY COALESCE(rc.cr_year, rc.wr_year, sp.d_year), COALESCE(rc.cr_color, rc.wr_color, sp.i_color)
)

SELECT *
FROM final_agg
ORDER BY year DESC, total_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
