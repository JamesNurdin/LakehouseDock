WITH promo_returns AS (
  SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    p.p_channel_email,
    p.p_start_date_sk,
    p.p_end_date_sk,
    p.p_cost,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    COUNT(*) AS return_count,
    AVG(sr.sr_return_amt_inc_tax) AS avg_return_inc_tax
  FROM promotion p
  JOIN store_returns sr
    ON sr.sr_item_sk = p.p_item_sk
   AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  WHERE p.p_channel_email = 'Y'
    AND p.p_response_target = 1
    AND p.p_promo_name IN ('able', 'anti')
  GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    p.p_channel_email,
    p.p_start_date_sk,
    p.p_end_date_sk,
    p.p_cost
  HAVING COUNT(*) >= 5
)
SELECT
  promo_id,
  promo_name,
  total_return_inc_tax,
  total_refunded_cash,
  total_net_loss,
  total_return_qty,
  return_count,
  avg_return_inc_tax,
  ROUND(total_return_inc_tax / NULLIF(p_cost, 0), 2) AS return_to_cost_ratio,
  RANK() OVER (ORDER BY total_return_inc_tax DESC) AS return_rank
FROM promo_returns
ORDER BY total_return_inc_tax DESC
LIMIT 10
