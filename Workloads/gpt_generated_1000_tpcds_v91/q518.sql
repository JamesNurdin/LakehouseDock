WITH raw_agg AS (
  SELECT
    i.i_item_id AS i_item_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txns,
    COUNT(DISTINCT cr.cr_order_number) AS return_txns
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN time_dim t_returns ON cr.cr_returned_time_sk = t_returns.t_time_sk
  WHERE t_sales.t_hour BETWEEN 9 AND 17
    AND t_sales.t_sub_shift = 'morning'
    AND t_returns.t_hour BETWEEN 9 AND 17
    AND t_returns.t_sub_shift = 'morning'
    AND i.i_class = 'pop'
    AND ss.ss_ext_sales_price > 1000
    AND cr.cr_return_amount > 50
    AND t_sales.t_second < 10
  GROUP BY i.i_item_id
),
net_agg AS (
  SELECT
    i_item_id,
    total_sales,
    total_returns,
    (total_sales - total_returns) AS net_sales,
    total_sales / NULLIF(sales_txns, 0) AS avg_sales_per_txn,
    total_returns / NULLIF(return_txns, 0) AS avg_return_per_txn
  FROM raw_agg
  WHERE total_sales > 0
)
(
  SELECT i_item_id, net_sales FROM net_agg WHERE net_sales > 2000
  UNION
  SELECT i_item_id, net_sales FROM net_agg WHERE total_sales > 5000
)
INTERSECT
SELECT i_item_id, net_sales FROM net_agg WHERE avg_sales_per_txn > 200
LIMIT 100
