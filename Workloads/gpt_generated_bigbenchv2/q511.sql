WITH sales_by_item AS (
  SELECT
    i.i_category_name,
    i.i_item_id,
    i.i_name,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers,
    AVG(i.i_price - i.i_comp_price) AS avg_discount
  FROM web_sales ws
  JOIN items i
    ON ws.ws_item_id = i.i_item_id
  WHERE i.i_price > 20.00
  GROUP BY i.i_category_name, i.i_item_id, i.i_name
)
SELECT
  i_category_name,
  i_item_id,
  i_name,
  total_quantity,
  total_revenue,
  distinct_customers,
  avg_discount,
  total_revenue / total_quantity AS revenue_per_unit,
  RANK() OVER (PARTITION BY i_category_name ORDER BY total_revenue DESC) AS category_item_rank
FROM sales_by_item
ORDER BY total_revenue DESC
LIMIT 100
