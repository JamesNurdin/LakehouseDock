SELECT
  d_cs_sold.d_year AS sales_year,
  d_cs_sold.d_month_seq AS month_of_year,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  SUM(ws.ws_net_profit) AS total_web_profit,
  COUNT(DISTINCT s.s_store_sk) FILTER (WHERE d_store_closed.d_year = d_cs_sold.d_year) AS stores_closed_in_sales_year,
  COUNT(DISTINCT wp.wp_web_page_sk) FILTER (WHERE d_wp_creation.d_year = d_cs_sold.d_year) AS web_pages_created_in_sales_year,
  COUNT(DISTINCT wp.wp_web_page_sk) FILTER (WHERE d_wp_access.d_year = d_cs_sold.d_year) AS web_pages_accessed_in_sales_year,
  AVG(cs.cs_quantity) AS avg_catalog_quantity,
  AVG(ws.ws_quantity) AS avg_web_quantity
FROM catalog_sales cs
JOIN date_dim d_cs_sold
  ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship
  ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_cs_sold.d_year BETWEEN 2000 AND 2005
GROUP BY d_cs_sold.d_year, d_cs_sold.d_month_seq
ORDER BY d_cs_sold.d_year, d_cs_sold.d_month_seq
