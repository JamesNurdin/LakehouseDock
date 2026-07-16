WITH sales_agg AS (
  SELECT
    s.s_state AS store_state,
    cd.cd_gender AS gender,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    AVG(ss.ss_ext_discount_amt) AS avg_discount
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE s.s_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
    AND ca.ca_country = 'United States'
  GROUP BY s.s_state, cd.cd_gender
),
returns_agg AS (
  SELECT
    s.s_state AS store_state,
    cd.cd_gender AS gender,
    SUM(sr.sr_refunded_cash) AS total_refunded,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE s.s_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
    AND ca.ca_country = 'United States'
    AND sr.sr_refunded_cash > 0
  GROUP BY s.s_state, cd.cd_gender
),
top_reason AS (
  SELECT
    s_state,
    r_reason_desc,
    reason_refunded,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY reason_refunded DESC) AS rn
  FROM (
    SELECT
      s.s_state AS s_state,
      r.r_reason_desc,
      SUM(sr.sr_refunded_cash) AS reason_refunded
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
    GROUP BY s.s_state, r.r_reason_desc
  ) agg
)
SELECT
  sa.store_state,
  sa.gender,
  sa.total_sales,
  sa.total_profit,
  sa.sales_cnt,
  sa.avg_discount,
  COALESCE(ra.total_refunded, 0) AS total_refunded,
  COALESCE(ra.return_cnt, 0) AS return_cnt,
  CASE WHEN sa.total_sales > 0 THEN (COALESCE(ra.total_refunded, 0) / sa.total_sales) ELSE 0 END AS refund_rate,
  CASE WHEN sa.sales_cnt > 0 THEN (COALESCE(ra.return_cnt, 0) * 1.0 / sa.sales_cnt) ELSE 0 END AS return_ratio,
  tr.r_reason_desc AS top_return_reason,
  tr.reason_refunded AS top_reason_refunded
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.store_state = ra.store_state AND sa.gender = ra.gender
LEFT JOIN top_reason tr
  ON sa.store_state = tr.s_state AND tr.rn = 1
ORDER BY refund_rate DESC
LIMIT 50
