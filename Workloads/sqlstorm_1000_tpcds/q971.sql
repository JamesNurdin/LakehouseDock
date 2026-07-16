WITH sales_by_category AS (
  SELECT
    d.d_year AS year,
    s.s_state AS state,
    i.i_category AS category,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year, s.s_state, i.i_category

  UNION ALL

  SELECT
    d.d_year AS year,
    ca.ca_state AS state,
    i.i_category AS category,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year, ca.ca_state, i.i_category

  UNION ALL

  SELECT
    d.d_year AS year,
    cc.cc_state AS state,
    i.i_category AS category,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
  GROUP BY d.d_year, cc.cc_state, i.i_category
)

SELECT
  year,
  state,
  category,
  channel,
  total_sales,
  total_profit,
  total_quantity,
  ROW_NUMBER() OVER (PARTITION BY year, state ORDER BY total_sales DESC) AS sales_rank
FROM sales_by_category
WHERE total_sales > 0
ORDER BY year, state, sales_rank
LIMIT 200
