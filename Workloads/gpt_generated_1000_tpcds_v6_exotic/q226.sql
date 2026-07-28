WITH combined_returns AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    cr.cr_return_amount AS return_amount,
    cr.cr_return_quantity AS quantity,
    cr.cr_net_loss AS net_loss,
    'catalog' AS channel,
    r.r_reason_desc AS reason_desc,
    ca.ca_state AS state,
    CASE 
      WHEN cr.cr_return_amount > 1000 THEN 'high'
      WHEN cr.cr_return_amount > 500 THEN 'medium'
      ELSE 'low'
    END AS amount_category
  FROM catalog_returns cr
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_return_amount IS NOT NULL
    AND cr.cr_return_amount > 0
    AND cr.cr_return_quantity >= 1
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND r.r_reason_desc LIKE '%defect%'
),

store_agg AS (
  SELECT
    sr.sr_returned_date_sk AS date_sk,
    sr.sr_return_amt AS return_amount,
    sr.sr_return_quantity AS quantity,
    sr.sr_net_loss AS net_loss,
    'store' AS channel,
    r.r_reason_desc AS reason_desc,
    ca.ca_state AS state,
    CASE 
      WHEN sr.sr_return_amt > 1000 THEN 'high'
      WHEN sr.sr_return_amt > 500 THEN 'medium'
      ELSE 'low'
    END AS amount_category
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_return_amt IS NOT NULL
    AND sr.sr_return_amt > 0
    AND sr.sr_return_quantity >= 1
    AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND r.r_reason_desc LIKE '%defect%'
),

web_agg AS (
  SELECT
    wr.wr_returned_date_sk AS date_sk,
    wr.wr_return_amt AS return_amount,
    wr.wr_return_quantity AS quantity,
    wr.wr_net_loss AS net_loss,
    'web' AS channel,
    r.r_reason_desc AS reason_desc,
    ca.ca_state AS state,
    CASE 
      WHEN wr.wr_return_amt > 1000 THEN 'high'
      WHEN wr.wr_return_amt > 500 THEN 'medium'
      ELSE 'low'
    END AS amount_category
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_return_amt IS NOT NULL
    AND wr.wr_return_amt > 0
    AND wr.wr_return_quantity >= 1
    AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND r.r_reason_desc LIKE '%defect%'
),

all_returns AS (
  SELECT * FROM combined_returns
  UNION ALL
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
)

SELECT
  channel,
  reason_desc,
  state,
  amount_category,
  SUM(return_amount) AS total_return_amount,
  SUM(quantity) AS total_quantity,
  AVG(net_loss) AS avg_net_loss,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY SUM(return_amount) DESC) AS channel_rank
FROM all_returns
GROUP BY GROUPING SETS (
  (channel, reason_desc, state, amount_category),
  (channel, reason_desc, state),
  (channel, reason_desc),
  (channel)
)
HAVING SUM(return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
