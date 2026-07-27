SELECT
    i_brand AS grouping_name,
    'brand' AS grouping_type,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_return_quantity) AS total_return_quantity
FROM web_returns
JOIN item ON web_returns.wr_item_sk = item.i_item_sk
WHERE i_rec_start_date >= DATE '2000-01-01'
  AND i_manager_id = 3
GROUP BY i_brand

UNION ALL

SELECT
    i_category AS grouping_name,
    'category' AS grouping_type,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_return_quantity) AS total_return_quantity
FROM web_returns
JOIN item ON web_returns.wr_item_sk = item.i_item_sk
WHERE i_rec_end_date <= DATE '2000-12-31'
  AND i_manager_id = 26
GROUP BY i_category
LIMIT 100
