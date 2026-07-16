WITH
store_agg AS (
  SELECT
    s.s_state AS state,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(*) AS transaction_cnt
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ss.ss_sold_date_sk >= 2450000
    AND s.s_state IN ('CA', 'TX', 'NY')
  GROUP BY s.s_state, cd.cd_gender, cd.cd_marital_status
  HAVING SUM(ss.ss_quantity) > 100
),
web_agg AS (
  SELECT
    NULL AS state,
    cd.cd_gender AS gender,
    cd.cd_marital_status AS marital_status,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(*) AS transaction_cnt
  FROM web_sales ws
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_sold_date_sk >= 2450000
    AND ws.ws_quantity > 0
  GROUP BY cd.cd_gender, cd.cd_marital_status
  HAVING SUM(ws.ws_quantity) > 100
)
SELECT
  channel,
  state,
  gender,
  marital_status,
  total_profit,
  total_quantity,
  avg_purchase_estimate,
  transaction_cnt,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT 'store' AS channel,
         state,
         gender,
         marital_status,
         total_profit,
         total_quantity,
         avg_purchase_estimate,
         transaction_cnt
  FROM store_agg
  UNION ALL
  SELECT 'web' AS channel,
         state,
         gender,
         marital_status,
         total_profit,
         total_quantity,
         avg_purchase_estimate,
         transaction_cnt
  FROM web_agg
) combined
ORDER BY profit_rank
LIMIT 200
