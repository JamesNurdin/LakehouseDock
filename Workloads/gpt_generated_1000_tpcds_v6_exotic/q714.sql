SELECT *
FROM (
   SELECT
     item.i_manufact_id AS manufact_id,
     SUM(catalog_returns.cr_return_amount) AS total_amount,
     CASE
       WHEN SUM(catalog_returns.cr_return_quantity) < 50 THEN 'Low'
       WHEN SUM(catalog_returns.cr_return_quantity) BETWEEN 50 AND 200 THEN 'Medium'
       ELSE 'High'
     END AS qty_category,
     (SELECT COUNT(*) FROM item i2 WHERE i2.i_manufact_id = item.i_manufact_id) AS item_count,
     'return' AS source
   FROM catalog_returns
   JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
   JOIN time_dim ON catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
   WHERE time_dim.t_shift = 'first'
     AND item.i_wholesale_cost > 1.0
   GROUP BY item.i_manufact_id
   UNION ALL
   SELECT
     item.i_manufact_id AS manufact_id,
     SUM(web_sales.ws_ext_sales_price) AS total_amount,
     CASE
       WHEN SUM(web_sales.ws_quantity) < 100 THEN 'Low'
       WHEN SUM(web_sales.ws_quantity) BETWEEN 100 AND 500 THEN 'Medium'
       ELSE 'High'
     END AS qty_category,
     (SELECT COUNT(*) FROM item i2 WHERE i2.i_manufact_id = item.i_manufact_id) AS item_count,
     'sale' AS source
   FROM web_sales
   JOIN item ON web_sales.ws_item_sk = item.i_item_sk
   JOIN time_dim ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
   WHERE time_dim.t_shift = 'first'
     AND item.i_wholesale_cost > 1.0
   GROUP BY item.i_manufact_id
) AS combined
ORDER BY manufact_id, source
LIMIT 100
