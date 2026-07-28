WITH joined_data AS (
  SELECT
    sr.sr_return_amt,
    ws.ws_net_paid,
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    r.r_reason_desc,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    sm.sm_carrier,
    ws.ws_quantity
  FROM store_returns sr
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE r.r_reason_id = 'AAAAAAAAABAAAAAA'
    AND sm.sm_carrier IN ('UPS', 'FEDEX')
    AND cd.cd_credit_rating = 'Low Risk'
    AND hd.hd_buy_potential = 'Medium'
    AND ws.ws_quantity > 5
),
store_agg AS (
  SELECT
    s_store_sk,
    s_store_name,
    s_state,
    SUM(sr_return_amt) AS total_return,
    SUM(ws_net_paid) AS total_sales,
    COUNT(*) AS trx_cnt
  FROM joined_data
  GROUP BY s_store_sk, s_store_name, s_state
)
SELECT
  s_state,
  AVG(total_return) AS avg_return_per_store,
  AVG(total_sales) AS avg_sales_per_store,
  SUM(trx_cnt) AS total_transactions
FROM store_agg
GROUP BY s_state
HAVING AVG(total_return) > 5000
ORDER BY avg_return_per_store DESC
LIMIT 100
