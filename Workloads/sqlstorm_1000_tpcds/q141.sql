SELECT i.i_product_name, SUM(s.ss_ext_sales_price) AS revenue
FROM store_sales s
JOIN item i ON s.ss_item_sk = i.i_item_sk
GROUP BY i.i_product_name
ORDER BY revenue DESC
LIMIT 10
