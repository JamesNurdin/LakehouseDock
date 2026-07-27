WITH sr_data AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_store_sk,
    sr.sr_reason_sk,
    sr.sr_return_amt,
    sr.sr_net_loss,
    cd.cd_credit_rating,
    cd.cd_marital_status,
    st.s_store_name,
    rs.r_reason_desc
  FROM store_returns sr
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store st
    ON sr.sr_store_sk = st.s_store_sk
  JOIN reason rs
    ON sr.sr_reason_sk = rs.r_reason_sk
  WHERE cd.cd_credit_rating = 'Good'
    AND cd.cd_marital_status = 'M'
    AND st.s_state = 'CA'
    AND rs.r_reason_desc LIKE '%damaged%'
),
ws_data AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_ship_mode_sk,
    ws.ws_promo_sk,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    cd2.cd_credit_rating,
    cd2.cd_marital_status,
    sm.sm_type,
    p.p_promo_name,
    p.p_discount_active
  FROM web_sales ws
  JOIN customer_demographics cd2
    ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  WHERE cd2.cd_credit_rating = 'Good'
    AND cd2.cd_marital_status = 'M'
    AND sm.sm_type = 'AIR'
    AND p.p_discount_active = 'Y'
)
SELECT *
FROM (
  SELECT
    'store_return' AS source,
    sr_returned_date_sk AS date_sk,
    COALESCE(s_store_name, 'Unknown Store') AS store_name,
    r_reason_desc AS reason,
    SUM(sr_return_amt) AS total_amount,
    SUM(sr_net_loss) AS total_loss,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(sr_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS amount_category
  FROM sr_data
  GROUP BY sr_returned_date_sk, s_store_name, r_reason_desc

  UNION ALL

  SELECT
    'web_sale' AS source,
    ws_sold_date_sk AS date_sk,
    sm_type AS store_name,
    p_promo_name AS reason,
    SUM(ws_ext_sales_price) AS total_amount,
    SUM(ws_net_profit) AS total_loss,
    COUNT(*) AS transaction_cnt,
    CASE WHEN SUM(ws_ext_sales_price) > 20000 THEN 'High' ELSE 'Low' END AS amount_category
  FROM ws_data
  GROUP BY ws_sold_date_sk, sm_type, p_promo_name
) AS combined
ORDER BY total_amount DESC
LIMIT 100
