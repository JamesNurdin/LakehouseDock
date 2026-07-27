WITH avg_profit AS (
  SELECT AVG(cs_net_profit) AS avg_profit
  FROM catalog_sales
)
SELECT department,
       total_sales,
       order_count,
       avg_profit
FROM (
  SELECT cp.cp_department AS department,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         COUNT(*) AS order_count,
         (SELECT avg_profit FROM avg_profit) AS avg_profit
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
  WHERE cp.cp_type = 'Catalog'
    AND cs.cs_list_price > 120.00
    AND ca.ca_state = 'CA'
  GROUP BY cp.cp_department

  UNION ALL

  SELECT cp.cp_department AS department,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         COUNT(*) AS order_count,
         (SELECT avg_profit FROM avg_profit) AS avg_profit
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_state = 'TX'
    AND cs.cs_net_profit > 1000.00
    AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_address_sk = cs.cs_bill_addr_sk
          AND ca2.ca_country = 'United States'
    )
  GROUP BY cp.cp_department
) combined
ORDER BY total_sales DESC, department
LIMIT 100
