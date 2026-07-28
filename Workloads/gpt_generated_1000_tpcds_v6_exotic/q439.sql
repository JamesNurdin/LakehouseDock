WITH catalog_agg AS (
   SELECT cp.cp_department AS dept,
          w.w_state AS state,
          SUM(cs.cs_ext_sales_price) AS sales,
          SUM(cs.cs_net_profit) AS profit
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE d1.d_year = 2001
     AND cp.cp_department = 'DEPARTMENT'
     AND w.w_state = 'TX'
     AND sm.sm_type = 'AIR'
   GROUP BY cp.cp_department, w.w_state
),
web_agg AS (
   SELECT wp.wp_type AS dept,
          w.w_state AS state,
          SUM(ws.ws_ext_sales_price) AS sales,
          SUM(ws.ws_net_profit) AS profit
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE d2.d_year = 2001
     AND wp.wp_type = 'CONTENT'
     AND w.w_state = 'TX'
     AND sm.sm_type = 'AIR'
   GROUP BY wp.wp_type, w.w_state
),
combined AS (
   SELECT dept, state, sales, profit FROM catalog_agg
   UNION ALL
   SELECT dept, state, sales, profit FROM web_agg
)
SELECT
   c.dept,
   c.state,
   SUM(c.sales) AS total_sales,
   SUM(c.profit) AS total_profit,
   AVG(c.profit) AS avg_profit
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM customer_address ca_ex
    WHERE ca_ex.ca_state = c.state
      AND ca_ex.ca_country = 'USA'
      AND ca_ex.ca_gmt_offset > 5.00
)
GROUP BY GROUPING SETS ((c.dept, c.state), (c.dept), (c.state), ())
HAVING SUM(c.sales) > 50000
   AND AVG(c.profit) > 10
ORDER BY total_sales DESC
LIMIT 100
