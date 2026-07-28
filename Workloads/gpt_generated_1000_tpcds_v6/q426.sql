WITH base AS (
  SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    ss.ss_ticket_number,
    ss.ss_store_sk,
    ss.ss_net_profit,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_reversed_charge,
    sr.sr_net_loss,
    r.r_reason_desc,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    CASE
      WHEN sr.sr_fee > 50 THEN 'HIGH_FEE'
      ELSE 'NORMAL_FEE'
    END AS fee_category
  FROM tpcds.customer_address ca
  JOIN tpcds.store_sales ss
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_addr_sk = ca.ca_address_sk
  JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returning_addr_sk = ca.ca_address_sk
   AND wr.wr_reason_sk = r.r_reason_sk
)
SELECT
  ca_address_id,
  ca_city,
  ca_state,
  fee_category,
  r_reason_desc,
  SUM(sr_return_amt + wr_return_amt) AS total_return_amount,
  SUM(sr_net_loss + wr_net_loss) AS total_net_loss,
  SUM(ss_net_profit) AS total_store_profit,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(sr_net_loss + wr_net_loss) DESC) AS rn_state,
  RANK() OVER (ORDER BY SUM(sr_net_loss + wr_net_loss) DESC) AS overall_rank,
  (SELECT AVG(sr_fee) FROM tpcds.store_returns WHERE sr_fee > 30) AS avg_high_fee
FROM base
WHERE
  ca_state = 'CA'
  AND r_reason_desc LIKE '%size%'
  AND sr_return_quantity > 1
  AND wr_return_quantity > 0
  AND ss_net_profit > 0
GROUP BY
  ca_address_id,
  ca_city,
  ca_state,
  fee_category,
  r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
