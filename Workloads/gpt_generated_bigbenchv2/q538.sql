WITH store_rev AS (
  SELECT c.c_customer_id,
         c.c_name,
         SUM(ss.ss_quantity * i.i_price) AS revenue
  FROM store_sales ss
  JOIN customers c ON ss.ss_customer_id = c.c_customer_id
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY c.c_customer_id, c.c_name
),
web_rev AS (
  SELECT c.c_customer_id,
         c.c_name,
         SUM(ws.ws_quantity * i.i_price) AS revenue
  FROM web_sales ws
  JOIN customers c ON ws.ws_customer_id = c.c_customer_id
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY c.c_customer_id, c.c_name
),
combined AS (
  SELECT COALESCE(s.c_customer_id, w.c_customer_id) AS c_customer_id,
         COALESCE(s.c_name, w.c_name) AS c_name,
         COALESCE(s.revenue, 0) + COALESCE(w.revenue, 0) AS total_revenue
  FROM store_rev s
  FULL OUTER JOIN web_rev w ON s.c_customer_id = w.c_customer_id
)
SELECT c_customer_id,
       c_name,
       total_revenue
FROM combined
ORDER BY total_revenue DESC
LIMIT 10
