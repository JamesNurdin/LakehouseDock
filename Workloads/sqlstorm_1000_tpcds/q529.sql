WITH sales_union AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_net_profit AS net_profit,
         cs.cs_promo_sk AS promo_sk,
         cs.cs_call_center_sk AS cc_sk,
         CAST(NULL AS integer) AS store_sk,
         CAST(NULL AS integer) AS warehouse_sk,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_net_profit,
         ss.ss_promo_sk,
         CAST(NULL AS integer),
         ss.ss_store_sk,
         CAST(NULL AS integer),
         'store'
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_net_profit,
         ws.ws_promo_sk,
         CAST(NULL AS integer),
         CAST(NULL AS integer),
         ws.ws_warehouse_sk,
         'web'
  FROM web_sales ws
), agg_sales AS (
  SELECT
    d.d_year,
    COALESCE(cc.cc_state, st.s_state, wh.w_state) AS state,
    su.channel,
    SUM(su.net_profit) AS total_profit,
    AVG(su.net_profit) AS avg_profit,
    COUNT(*) AS transaction_cnt
  FROM sales_union su
  JOIN date_dim d ON su.date_sk = d.d_date_sk
  JOIN promotion p ON su.promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON su.cc_sk = cc.cc_call_center_sk
  LEFT JOIN store st ON su.store_sk = st.s_store_sk
  LEFT JOIN warehouse wh ON su.warehouse_sk = wh.w_warehouse_sk
  WHERE p.p_discount_active = 'Y'
    AND d.d_year BETWEEN 1998 AND 2001
  GROUP BY d.d_year,
           COALESCE(cc.cc_state, st.s_state, wh.w_state),
           su.channel
)
SELECT
  d_year,
  state,
  channel,
  total_profit,
  avg_profit,
  transaction_cnt,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY d_year, profit_rank
