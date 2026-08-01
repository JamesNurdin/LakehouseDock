WITH combined AS (
    SELECT i.i_item_id AS item_id,
           i.i_product_name AS product_name,
           i.i_category AS category,
           w.w_warehouse_name AS warehouse_name,
           inv.inv_quantity_on_hand AS quantity_on_hand,
           CAST(NULL AS integer) AS return_quantity,
           CAST(NULL AS decimal(7,2)) AS return_amount,
           inv.inv_date_sk AS date_sk,
           'inventory' AS source
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND w.w_city = 'San Francisco'

    UNION ALL

    SELECT i.i_item_id AS item_id,
           i.i_product_name AS product_name,
           i.i_category AS category,
           CAST(NULL AS varchar) AS warehouse_name,
           CAST(NULL AS integer) AS quantity_on_hand,
           wr.wr_return_quantity AS return_quantity,
           wr.wr_return_amt AS return_amount,
           wr.wr_returned_date_sk AS date_sk,
           'returns' AS source
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_quantity > 0
      AND wp.wp_type = 'product'
)
SELECT item_id,
       product_name,
       category,
       warehouse_name,
       quantity_on_hand,
       return_quantity,
       return_amount,
       source,
       CASE
           WHEN source = 'inventory' AND quantity_on_hand > 100 THEN 'High Stock'
           WHEN source = 'returns' AND return_quantity > 5 THEN 'High Returns'
           ELSE 'Normal'
       END AS status,
       SUM(COALESCE(return_quantity, 0)) OVER (
           PARTITION BY item_id
           ORDER BY date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_returns
FROM combined
ORDER BY date_sk DESC
LIMIT 100
