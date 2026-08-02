WITH joined_data AS (
   SELECT
      s.s_market_manager,
      cd.cd_gender,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_paid,
      ws.ws_order_number
   FROM tpcds.store_returns sr
   JOIN tpcds.customer_demographics cd
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN tpcds.web_sales ws
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_gender = 'F'
     AND cd.cd_marital_status = 'M'
     AND cd.cd_dep_count BETWEEN 1 AND 4
     AND cd.cd_dep_college_count >= 1
     AND s.s_state = 'CA'
     AND sr.sr_store_credit > 20.00
     AND sr.sr_reversed_charge < 500.00
     AND ws.ws_quantity >= 2
     AND ws.ws_sales_price > 100.00
),
agg_all AS (
   SELECT
      s_market_manager,
      cd_gender,
      SUM(sr_return_amt) AS total_return_amt,
      SUM(sr_return_quantity) AS total_return_qty,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_paid) AS total_net_paid,
      COUNT(DISTINCT ws_order_number) AS order_cnt
   FROM joined_data
   GROUP BY ROLLUP(s_market_manager, cd_gender)
   HAVING SUM(sr_return_amt) > 500.00
),
agg_excluded AS (
   SELECT
      s_market_manager,
      cd_gender,
      SUM(sr_return_amt) AS total_return_amt,
      SUM(sr_return_quantity) AS total_return_qty,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_paid) AS total_net_paid,
      COUNT(DISTINCT ws_order_number) AS order_cnt
   FROM joined_data
   WHERE s_market_manager = 'Edward Stone'
   GROUP BY ROLLUP(s_market_manager, cd_gender)
   HAVING SUM(sr_return_amt) > 500.00
)
SELECT
   s_market_manager,
   cd_gender,
   total_return_amt,
   total_return_qty,
   total_sales,
   total_net_paid,
   order_cnt
FROM agg_all
EXCEPT
SELECT
   s_market_manager,
   cd_gender,
   total_return_amt,
   total_return_qty,
   total_sales,
   total_net_paid,
   order_cnt
FROM agg_excluded
ORDER BY total_return_amt DESC
