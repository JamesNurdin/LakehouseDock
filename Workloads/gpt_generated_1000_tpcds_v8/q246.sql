WITH
  cs_agg AS (
    SELECT
      cs_bill_customer_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_promo_sk,
      SUM(cs_net_profit) AS cs_total_profit,
      COUNT(*) AS cs_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY
      cs_bill_customer_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_promo_sk
  ),
  ws_agg AS (
    SELECT
      ws_bill_customer_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_web_site_sk,
      ws_ship_mode_sk,
      ws_promo_sk,
      SUM(ws_net_paid) AS ws_total_sales,
      COUNT(*) AS ws_cnt
    FROM web_sales
    WHERE ws_sold_date_sk IN (
      SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY
      ws_bill_customer_sk,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_web_site_sk,
      ws_ship_mode_sk,
      ws_promo_sk
  ),
  qualified_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_year = 1955
    EXCEPT
    SELECT sr.sr_customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
  )
SELECT
  c.c_customer_id,
  d_sold.d_year,
  cc.cc_name,
  sm.sm_type,
  p.p_promo_name,
  cs_agg.cs_total_profit,
  ws_agg.ws_total_sales,
  ws_agg.ws_cnt,
  (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk) AS web_return_cnt,
  ca.ca_city,
  hd.hd_income_band_sk,
  r.r_reason_desc,
  st.s_store_name,
  max_ws.max_paid
FROM qualified_customers qc
JOIN customer c ON qc.c_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN cs_agg ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sold ON cs_agg.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs_agg.cs_sold_time_sk = t_sold.t_time_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws ON ws_agg.ws_sold_date_sk = d_ws.d_date_sk
JOIN ship_mode sm_ws ON ws_agg.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws ON ws_agg.ws_promo_sk = p_ws.p_promo_sk
JOIN web_site ws ON ws_agg.ws_web_site_sk = ws.web_site_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN store st ON sr.sr_store_sk = st.s_store_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
  SELECT MAX(ws_inner.ws_net_paid) AS max_paid
  FROM web_sales ws_inner
  WHERE ws_inner.ws_bill_customer_sk = c.c_customer_sk
) max_ws
WHERE
  cc.cc_state = 'CA'
  AND ca.ca_country = 'United States'
  AND r.r_reason_desc = 'Did not get it on time'
  AND NOT EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_customer_sk = c.c_customer_sk
      AND sr2.sr_return_quantity > 10
  )
ORDER BY cs_agg.cs_total_profit DESC
OFFSET 0 LIMIT 100
