WITH sales AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_ticket_number,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_net_paid_inc_tax,
    ss.ss_net_profit,
    s.s_store_name,
    s.s_state
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE s.s_state IN ('AZ', 'CA')
    AND ca.ca_state = s.s_state
    AND cd.cd_credit_rating = 'A'
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
),
returns AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_ticket_number,
    sr.sr_item_sk,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    r.r_reason_desc
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
  JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
  JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
  WHERE s2.s_state IN ('AZ', 'CA')
    AND ca2.ca_state = s2.s_state
    AND cd2.cd_credit_rating = 'A'
    AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
  sales.s_store_name,
  sales.s_state,
  returns.r_reason_desc,
  SUM(sales.ss_quantity) AS total_sales_qty,
  SUM(sales.ss_net_paid_inc_tax) AS total_sales_amount,
  AVG(sales.ss_net_profit) AS avg_net_profit,
  SUM(returns.sr_return_quantity) AS total_return_qty,
  SUM(returns.sr_net_loss) AS total_return_loss,
  (SUM(returns.sr_net_loss) / NULLIF(SUM(sales.ss_net_paid_inc_tax), 0)) AS loss_ratio,
  RANK() OVER (PARTITION BY sales.s_state ORDER BY (SUM(returns.sr_net_loss) / NULLIF(SUM(sales.ss_net_paid_inc_tax), 0)) DESC) AS state_store_rank
FROM sales
JOIN returns
  ON sales.ss_ticket_number = returns.sr_ticket_number
 AND sales.ss_item_sk = returns.sr_item_sk
 AND sales.ss_store_sk = returns.sr_store_sk
GROUP BY sales.s_store_name, sales.s_state, returns.r_reason_desc
HAVING SUM(sales.ss_quantity) > 1000
ORDER BY loss_ratio DESC
LIMIT 5
