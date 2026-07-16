WITH sales_union AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    MIN(d.d_year) AS first_year,
    MAX(d.d_year) AS last_year,
    ss.ss_store_sk AS store_sk,
    COUNT(DISTINCT ss.ss_promo_sk) AS distinct_promo_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY ss.ss_customer_sk, ss.ss_store_sk
  UNION ALL
  SELECT
    cs.cs_bill_customer_sk AS customer_sk,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity,
    MIN(d.d_year) AS first_year,
    MAX(d.d_year) AS last_year,
    CAST(NULL AS INTEGER) AS store_sk,
    COUNT(DISTINCT cs.cs_promo_sk) AS distinct_promo_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY cs.cs_bill_customer_sk
  UNION ALL
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    MIN(d.d_year) AS first_year,
    MAX(d.d_year) AS last_year,
    CAST(NULL AS INTEGER) AS store_sk,
    COUNT(DISTINCT ws.ws_promo_sk) AS distinct_promo_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY ws.ws_bill_customer_sk
),

returns_union AS (
  SELECT
    sr.sr_customer_sk AS customer_sk,
    'store' AS channel,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    sr.sr_store_sk AS store_sk,
    COUNT(DISTINCT sr.sr_reason_sk) AS distinct_reason_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY sr.sr_customer_sk, sr.sr_store_sk
  UNION ALL
  SELECT
    cr.cr_returning_customer_sk AS customer_sk,
    'catalog' AS channel,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    CAST(NULL AS INTEGER) AS store_sk,
    COUNT(DISTINCT cr.cr_reason_sk) AS distinct_reason_cnt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY cr.cr_returning_customer_sk
  UNION ALL
  SELECT
    wr.wr_refunded_customer_sk AS customer_sk,
    'web' AS channel,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    CAST(NULL AS INTEGER) AS store_sk,
    COUNT(DISTINCT wr.wr_reason_sk) AS distinct_reason_cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
  GROUP BY wr.wr_refunded_customer_sk
),

customer_info AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
    c.c_email_address,
    cd.cd_gender,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
  FROM customer c
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)

SELECT
  ci.c_customer_id,
  ci.full_name,
  ci.c_email_address,
  s.channel,
  s.total_net_profit,
  COALESCE(r.total_net_loss, 0) AS total_net_loss,
  (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_gain,
  s.total_quantity,
  COALESCE(r.total_return_qty, 0) AS total_return_qty,
  s.distinct_promo_cnt,
  COALESCE(r.distinct_reason_cnt, 0) AS distinct_reason_cnt,
  CONCAT('CUST_', ci.c_customer_id) AS customer_key,
  CASE
    WHEN COALESCE(r.total_return_qty, 0) = 0 THEN 'No Returns'
    WHEN (COALESCE(r.total_return_qty, 0) * 1.0 / NULLIF(s.total_quantity, 0)) > 0.5 THEN 'High Return Rate'
    ELSE 'Normal Return Rate'
  END AS return_rate_category,
  CAST(
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) * 100.0
    / NULLIF(s.total_net_profit, 0)
    AS DOUBLE
  ) AS profit_margin_pct,
  AVG(s.total_net_profit) OVER (PARTITION BY s.channel) AS avg_channel_profit,
  SUM(s.total_net_profit) OVER (PARTITION BY s.channel) AS total_channel_profit,
  ROW_NUMBER() OVER (PARTITION BY s.channel ORDER BY (s.total_net_profit - COALESCE(r.total_net_loss, 0)) DESC) AS channel_rank,
  (SELECT MAX(s2.total_net_profit) FROM sales_union s2 WHERE s2.channel = s.channel) AS max_channel_profit,
  (SELECT AVG(s3.total_net_profit) FROM sales_union s3 WHERE s3.customer_sk = s.customer_sk) AS customer_avg_profit,
  (SELECT COUNT(*) FROM sales_union s4 WHERE s4.channel = s.channel AND s4.total_net_profit > 0) AS active_customers_channel,
  CASE s.channel
    WHEN 'store' THEN (
      SELECT MAX(d.d_date)
      FROM store_sales ss
      JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
      WHERE ss.ss_customer_sk = s.customer_sk
    )
    WHEN 'catalog' THEN (
      SELECT MAX(d.d_date)
      FROM catalog_sales cs
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
      WHERE cs.cs_bill_customer_sk = s.customer_sk
    )
    WHEN 'web' THEN (
      SELECT MAX(d.d_date)
      FROM web_sales ws
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      WHERE ws.ws_bill_customer_sk = s.customer_sk
    )
    ELSE NULL
  END AS latest_transaction_date,
  CONCAT(
    substr(ci.c_email_address, 1, 2),
    '***',
    substr(ci.c_email_address, position('@' IN ci.c_email_address))
  ) AS masked_email,
  s.store_sk,
  st.s_store_name,
  st.s_city AS store_city,
  st.s_state AS store_state
FROM sales_union s
LEFT JOIN returns_union r
  ON s.customer_sk = r.customer_sk
 AND s.channel = r.channel
LEFT JOIN customer_info ci
  ON s.customer_sk = ci.c_customer_sk
LEFT JOIN store st
  ON s.store_sk = st.s_store_sk
WHERE (s.total_net_profit - COALESCE(r.total_net_loss, 0)) > 0
  AND ci.c_customer_id IS NOT NULL
ORDER BY s.channel, net_gain DESC
LIMIT 100
