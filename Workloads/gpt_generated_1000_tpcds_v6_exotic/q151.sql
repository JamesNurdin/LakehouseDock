WITH
  catalog_agg AS (
    SELECT
      d.d_year,
      cp.cp_department,
      cp.cp_catalog_page_number,
      CAST(NULL AS varchar) AS web_name,
      SUM(cs.cs_net_paid) AS total_net_paid,
      SUM(cs.cs_net_profit) AS total_net_profit,
      COUNT(*) AS order_cnt,
      MIN(cs.cs_order_number) AS sample_order,
      'catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cp.cp_department IN ('Books', 'Electronics', 'Home')
      AND ca.ca_state = 'CA'
    GROUP BY ROLLUP (d.d_year, cp.cp_department, cp.cp_catalog_page_number)
  ),
  catalog_filtered AS (
    SELECT *
    FROM catalog_agg ca
    WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_order_number = ca.sample_order
    )
  ),
  web_agg AS (
    SELECT
      d.d_year,
      CAST(NULL AS varchar) AS cp_department,
      CAST(NULL AS integer) AS cp_catalog_page_number,
      wsit.web_name,
      SUM(ws.ws_net_paid) AS total_net_paid,
      SUM(ws.ws_net_profit) AS total_net_profit,
      COUNT(*) AS order_cnt,
      MIN(ws.ws_order_number) AS sample_order,
      'web' AS source
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wsit.web_class = 'A'
      AND ca.ca_state = 'CA'
    GROUP BY ROLLUP (d.d_year, wsit.web_name)
  ),
  combined AS (
    SELECT * FROM catalog_filtered
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT
  d_year,
  COALESCE(cp_department, web_name) AS category,
  cp_catalog_page_number,
  total_net_paid,
  total_net_profit,
  order_cnt,
  source,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
  CASE
    WHEN total_net_profit > (
      SELECT AVG(total_net_profit)
      FROM combined c2
      WHERE c2.d_year = outer_query.d_year
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_vs_avg
FROM combined outer_query
ORDER BY d_year, profit_rank
