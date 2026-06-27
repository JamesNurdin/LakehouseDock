WITH return_agg AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_item_sk,
    SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
  WHERE dr.d_year = 2001
  GROUP BY sr.sr_ticket_number, sr.sr_item_sk
)
SELECT
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  d.d_month_seq,
  SUM(ss.ss_net_paid) AS total_sales,
  COALESCE(SUM(r.total_return_loss), 0) AS total_returns_loss,
  SUM(ss.ss_net_paid) - COALESCE(SUM(r.total_return_loss), 0) AS net_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN return_agg r
  ON ss.ss_ticket_number = r.sr_ticket_number
  AND ss.ss_item_sk = r.sr_item_sk
WHERE d.d_year = 2001
GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
ORDER BY net_profit DESC
LIMIT 10
