WITH
  cs_agg AS (
    SELECT
      cs_order_number,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_call_center_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      cs_bill_cdemo_sk,
      cs_bill_hdemo_sk,
      SUM(cs_net_profit)        AS total_profit,
      COUNT(*)                  AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 5
    GROUP BY
      cs_order_number,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_call_center_sk,
      cs_warehouse_sk,
      cs_promo_sk,
      cs_bill_cdemo_sk,
      cs_bill_hdemo_sk
  ),
  diff_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 0
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
  ),
  store_cc_full AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_closed_date_sk      AS store_closed_date_sk,
      cc.cc_call_center_sk,
      cc.cc_closed_date_sk    AS cc_closed_date_sk
    FROM store s
    JOIN date_dim d1 ON s.s_closed_date_sk = d1.d_date_sk
    FULL OUTER JOIN (
      SELECT cc.cc_call_center_sk, cc.cc_closed_date_sk
      FROM call_center cc
      JOIN date_dim d2 ON cc.cc_closed_date_sk = d2.d_date_sk
    ) cc ON d1.d_date_sk = cc.cc_closed_date_sk
  )
SELECT
  cc.cc_name,
  d_sales.d_year,
  w.w_warehouse_name,
  sc.s_store_name,
  SUM(ca.total_profit)    AS total_profit_sum,
  COUNT(*)                AS order_count,
  AVG(ca.total_profit)   AS avg_profit,
  COUNT(DISTINCT sc.s_store_sk) AS distinct_store_cnt
FROM cs_agg ca
JOIN call_center cc
  ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sales
  ON ca.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON ca.cs_sold_time_sk = t_sales.t_time_sk
JOIN warehouse w
  ON ca.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON ca.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON ca.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ca.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
  AND inv.inv_date_sk = d_sales.d_date_sk
JOIN store_cc_full sc
  ON sc.store_closed_date_sk = d_sales.d_date_sk
JOIN web_site ws_site
  ON ws_site.web_open_date_sk = d_sales.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_sales.d_date_sk
WHERE
  ca.total_profit > 1000
  AND d_sales.d_year = 2001
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'F'
  AND EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_order_number = ca.cs_order_number
      AND wr.wr_return_amt > 0
  )
  AND ca.cs_order_number IN (SELECT cs_order_number FROM diff_orders)
GROUP BY
  cc.cc_name,
  d_sales.d_year,
  w.w_warehouse_name,
  sc.s_store_name
ORDER BY total_profit_sum DESC
LIMIT 100
