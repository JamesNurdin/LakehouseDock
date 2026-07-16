WITH
web_sales_agg AS (
  SELECT d.d_year AS sale_year,
         ca.ca_state AS state,
         SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, ca.ca_state
),
catalog_sales_agg AS (
  SELECT d.d_year AS sale_year,
         ca.ca_state AS state,
         SUM(cs.cs_net_profit) AS catalog_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, ca.ca_state
),
store_sales_agg AS (
  SELECT d.d_year AS sale_year,
         ca.ca_state AS state,
         SUM(ss.ss_net_profit) AS store_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
  GROUP BY d.d_year, ca.ca_state
)
SELECT
  COALESCE(w.sale_year, c.sale_year, s.sale_year) AS sale_year,
  COALESCE(w.state, c.state, s.state) AS state,
  w.web_profit,
  c.catalog_profit,
  s.store_profit
FROM web_sales_agg w
FULL OUTER JOIN catalog_sales_agg c ON w.sale_year = c.sale_year AND w.state = c.state
FULL OUTER JOIN store_sales_agg s ON COALESCE(w.sale_year, c.sale_year) = s.sale_year AND COALESCE(w.state, c.state) = s.state
ORDER BY sale_year, state
