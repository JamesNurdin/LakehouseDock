SELECT
  (date_dim.d_year * 100 + date_dim.d_month_seq) AS year_month_key,
  time_dim.t_hour,
  store.s_state,
  web_page.wp_type,
  COUNT(DISTINCT catalog_returns.cr_order_number) AS order_cnt,
  SUM(catalog_returns.cr_return_amount) AS total_return_amount,
  AVG(catalog_returns.cr_return_tax) AS avg_return_tax,
  SUM(catalog_returns.cr_fee) AS total_fee,
  SUM(catalog_returns.cr_return_quantity) AS total_quantity,
  CASE WHEN store.s_market_desc IS NULL THEN 'Unknown' ELSE store.s_market_desc END AS market_desc
FROM catalog_returns
JOIN date_dim
  ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
JOIN time_dim
  ON catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
JOIN store
  ON store.s_closed_date_sk = date_dim.d_date_sk
JOIN web_page
  ON web_page.wp_creation_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year BETWEEN 2000 AND 2005
  AND time_dim.t_hour BETWEEN 9 AND 17
  AND store.s_state = 'CA'
GROUP BY
  (date_dim.d_year * 100 + date_dim.d_month_seq),
  time_dim.t_hour,
  store.s_state,
  web_page.wp_type,
  CASE WHEN store.s_market_desc IS NULL THEN 'Unknown' ELSE store.s_market_desc END
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
