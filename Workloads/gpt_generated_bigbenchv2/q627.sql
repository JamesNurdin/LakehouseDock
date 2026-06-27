WITH aggregated AS (
  SELECT
    c_name,
    i_category_name,
    SUM(quantity) AS total_quantity,
    SUM(quantity * i_price) AS total_revenue
  FROM (
    SELECT
      customers.c_name,
      items.i_category_name,
      store_sales.ss_quantity AS quantity,
      items.i_price
    FROM store_sales
    JOIN customers ON store_sales.ss_customer_id = customers.c_customer_id
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    UNION ALL
    SELECT
      customers.c_name,
      items.i_category_name,
      web_sales.ws_quantity AS quantity,
      items.i_price
    FROM web_sales
    JOIN customers ON web_sales.ws_customer_id = customers.c_customer_id
    JOIN items ON web_sales.ws_item_id = items.i_item_id
  ) AS sales
  GROUP BY c_name, i_category_name
)
SELECT
  c_name,
  i_category_name,
  total_quantity,
  total_revenue,
  ROW_NUMBER() OVER (PARTITION BY i_category_name ORDER BY total_revenue DESC) AS rank_in_category
FROM aggregated
ORDER BY total_revenue DESC
LIMIT 20
