WITH promo_state_sales AS (
  SELECT
    p.p_promo_name,
    ca.ca_state,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    AND p.p_start_date_sk <= ss.ss_sold_date_sk
    AND p.p_end_date_sk >= ss.ss_sold_date_sk
  GROUP BY p.p_promo_name, ca.ca_state
  HAVING SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) > 0
)
SELECT
  p.p_promo_name,
  p.ca_state,
  p.total_sales_profit,
  p.total_return_loss,
  p.net_profit_after_returns,
  RANK() OVER (ORDER BY p.net_profit_after_returns DESC) AS promo_rank
FROM promo_state_sales p
ORDER BY p.net_profit_after_returns DESC
LIMIT 100
