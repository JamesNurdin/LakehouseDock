/*
  Goal: Compare aggregated monetary amounts by hour of the day from two different business processes –
  store returns (sum of return amount) and web sales (sum of extended sales price). The query joins each
  fact table to the time dimension on the allowed surrogate keys, applies hour‑range filters, aggregates
  the values, and combines the two result sets with UNION ALL for side‑by‑side analysis.
*/
SELECT
  td.t_hour AS hour,
  'store_return_amount' AS metric,
  SUM(sr.sr_return_amt) AS value
FROM store_returns AS sr
JOIN time_dim AS td
  ON sr.sr_return_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 12
GROUP BY td.t_hour

UNION ALL

SELECT
  td.t_hour AS hour,
  'web_sales_price' AS metric,
  SUM(ws.ws_ext_sales_price) AS value
FROM web_sales AS ws
JOIN time_dim AS td
  ON ws.ws_sold_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 13 AND 16
GROUP BY td.t_hour

ORDER BY hour, metric
LIMIT 100
