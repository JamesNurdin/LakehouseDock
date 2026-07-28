WITH sales_returns AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d.d_year,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_category,
    SUM(ss.ss_net_profit)               AS sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0))    AS return_loss
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk        = ss.ss_item_sk
   AND sr.sr_store_sk       = s.s_store_sk
  WHERE REGEXP_LIKE(s.s_store_name, 'Store[0-9]+')
    AND d.d_day_name LIKE '%day%'
  GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d.d_year,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Positive' ELSE 'Non-positive' END
)
SELECT
  s_store_id,
  CONCAT(s_store_name, ' (', s_state, ')') AS store_label,
  d_year,
  profit_category,
  sales_profit,
  return_loss,
  (sales_profit - return_loss) AS net_profit
FROM sales_returns
GROUP BY GROUPING SETS (
  (s_store_id, s_store_name, s_state, d_year, profit_category, sales_profit, return_loss),
  (s_store_id, s_store_name, s_state, d_year, sales_profit, return_loss),
  (s_store_id, s_store_name, s_state, sales_profit, return_loss),
  (d_year, sales_profit, return_loss),
  (sales_profit, return_loss)
)
ORDER BY d_year DESC NULLS LAST, s_store_id
LIMIT 100
