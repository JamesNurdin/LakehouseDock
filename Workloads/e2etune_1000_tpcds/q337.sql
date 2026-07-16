WITH store_return_agg AS (
  SELECT
    s.s_store_id,
    s.s_state,
    s.s_market_id,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    COUNT(*) AS cnt_returns
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
    AND s.s_state IN ('CA', 'TX', 'NY')
    AND s.s_gmt_offset BETWEEN -8.0 AND -5.0
  GROUP BY s.s_store_id, s.s_state, s.s_market_id
),
store_rank AS (
  SELECT
    s_store_id,
    s_state,
    s_market_id,
    total_net_loss,
    total_return_qty,
    avg_return_amt,
    cnt_returns,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
  FROM store_return_agg
)
SELECT
  sr.s_state,
  sr.s_market_id,
  SUM(sr.total_net_loss) AS market_total_loss,
  COUNT(*) FILTER (WHERE sr.loss_rank <= 5) AS top5_store_count,
  (SELECT COUNT(*) FROM promotion p WHERE p.p_channel_demo = 'Y') AS demo_promo_count
FROM store_rank sr
GROUP BY sr.s_state, sr.s_market_id
ORDER BY market_total_loss DESC
LIMIT 10
