WITH sales_data AS (
  SELECT
    s.s_store_name AS store_name,
    i.i_category AS category,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    ss.ss_net_paid AS net_amount,
    ss.ss_quantity AS qty,
    w.word
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS w(word)
  WHERE t.t_hour BETWEEN 9 AND 17
    AND i.i_category = 'shirts'
),
returns_data AS (
  SELECT
    s.s_store_name AS store_name,
    i.i_category AS category,
    CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS profit_status,
    -sr.sr_net_loss AS net_amount,
    -sr.sr_return_quantity AS qty,
    w.word
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS w(word)
  WHERE t.t_hour BETWEEN 9 AND 17
    AND i.i_category = 'shirts'
)
SELECT
  store_name,
  category,
  profit_status,
  SUM(net_amount) AS total_net,
  SUM(qty) AS total_qty,
  COUNT(DISTINCT word) AS distinct_word_count
FROM (
  SELECT store_name, category, profit_status, net_amount, qty, word FROM sales_data
  UNION ALL
  SELECT store_name, category, profit_status, net_amount, qty, word FROM returns_data
) u
GROUP BY GROUPING SETS (
  (store_name, category, profit_status),
  (store_name, profit_status),
  (store_name)
)
ORDER BY total_net DESC
LIMIT 100
