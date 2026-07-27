/* Goal: Rank call centers by total catalog net paid, combining catalog, web and store data, and classifying profit levels. */
WITH
  sales_fact AS (
    SELECT
      cs.cs_call_center_sk,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cc.cc_name,
      td.t_hour,
      hd.hd_buy_potential,
      ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND ib.ib_upper_bound <= 80000
      AND hd.hd_dep_count >= 2
  ),
  store_fact AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_return_time_sk,
      sr.sr_hdemo_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      s.s_store_name,
      td.t_hour AS store_hour,
      hd.hd_buy_potential AS store_buy_pot,
      hd.hd_dep_count AS store_dep_cnt
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_state = 'TX'
      AND td.t_hour BETWEEN 10 AND 18
      AND hd.hd_dep_count <= 4
  ),
  web_sales_fact AS (
    SELECT
      ws.ws_web_page_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_ship_hdemo_sk,
      ws.ws_net_paid,
      ws.ws_net_profit,
      td.t_hour AS web_hour,
      hd.hd_buy_potential AS web_buy_pot
    FROM web_sales ws
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 11 AND 19
      AND hd.hd_buy_potential = '>10000'
  ),
  union_returns AS (
    SELECT DISTINCT
      cr.cr_returned_date_sk   AS return_date_sk,
      cr.cr_returned_time_sk   AS return_time_sk,
      cr.cr_item_sk            AS item_sk,
      cr.cr_return_quantity    AS return_quantity,
      cr.cr_return_amount      AS return_amount,
      'catalog'                AS source
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cr.cr_return_quantity > 0
    UNION ALL
    SELECT DISTINCT
      wr.wr_returned_date_sk   AS return_date_sk,
      wr.wr_returned_time_sk   AS return_time_sk,
      wr.wr_item_sk            AS item_sk,
      wr.wr_return_quantity    AS return_quantity,
      wr.wr_return_amt         AS return_amount,
      'web'                    AS source
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE wr.wr_return_quantity > 0
  ),
  joined_data AS (
    SELECT
      sf.cc_name,
      sf.t_hour,
      sf.cs_net_paid,
      sf.cs_net_profit,
      sf.cs_order_number,
      wsf.ws_net_paid,
      wsf.ws_net_profit,
      stf.sr_return_amt,
      ur.source,
      sf.hd_buy_potential
    FROM sales_fact sf
    LEFT JOIN store_fact stf
      ON sf.cs_sold_time_sk = stf.sr_return_time_sk
    LEFT JOIN web_sales_fact wsf
      ON sf.cs_sold_time_sk = wsf.ws_sold_time_sk
    LEFT JOIN union_returns ur
      ON sf.cs_item_sk = ur.item_sk
    WHERE sf.hd_buy_potential <> '0-500'
  ),
  aggregated AS (
    SELECT
      cc_name,
      t_hour,
      SUM(cs_net_paid)      AS total_catalog_net_paid,
      SUM(cs_net_profit)    AS total_catalog_net_profit,
      SUM(ws_net_paid)      AS total_web_net_paid,
      SUM(sr_return_amt)    AS total_store_return_amt,
      COUNT(DISTINCT cs_order_number) AS distinct_orders,
      COUNT(*)               AS row_cnt
    FROM joined_data
    GROUP BY cc_name, t_hour
    HAVING COUNT(*) > 10
  )
SELECT
  cc_name,
  t_hour,
  total_catalog_net_paid,
  total_web_net_paid,
  total_store_return_amt,
  distinct_orders,
  CASE
    WHEN total_catalog_net_profit > 100000 THEN 'HIGH'
    WHEN total_catalog_net_profit BETWEEN 50000 AND 100000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  RANK() OVER (ORDER BY total_catalog_net_paid DESC) AS sales_rank
FROM aggregated
ORDER BY sales_rank
LIMIT 100
