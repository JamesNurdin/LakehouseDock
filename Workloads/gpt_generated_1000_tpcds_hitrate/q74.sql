SELECT
  i.i_item_id,
  i.i_item_desc,
  'sales' AS metric_type,
  SUM(cs.cs_ext_sales_price) AS total_amount
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND cs.cs_ext_sales_price > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales WHERE cs_sold_date_sk = 2451247)
GROUP BY i.i_item_id, i.i_item_desc

UNION

SELECT
  i.i_item_id,
  i.i_item_desc,
  'returns' AS metric_type,
  SUM(wr.wr_return_amt) AS total_amount
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND wr.wr_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns WHERE wr_returned_date_sk = 2451247)
GROUP BY i.i_item_id, i.i_item_desc

ORDER BY total_amount DESC
LIMIT 100
