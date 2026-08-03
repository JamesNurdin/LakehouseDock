WITH combined_sales AS (
  SELECT
    cp.cp_department AS department,
    cp.cp_catalog_number AS catalog_number,
    ca_store.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    ca_store.ca_state AS store_state,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(cs.cs_quantity) AS catalog_quantity,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_distinct_bill_cust,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_quantity) AS store_quantity,
    COUNT(DISTINCT ss.ss_customer_sk) AS store_distinct_cust,
    CASE
      WHEN SUM(cs.cs_net_profit) - SUM(ss.ss_net_profit) > 0 THEN 'Catalog > Store'
      ELSE 'Store >= Catalog'
    END AS profit_comparison
  FROM store_sales ss
  JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
  JOIN catalog_sales cs
    ON cs.cs_bill_addr_sk = ca_store.ca_address_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  WHERE cp.cp_department = 'Sports'
    AND ca_store.ca_state = 'CA'
    AND cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
  GROUP BY GROUPING SETS (
    (cp.cp_department, cp.cp_catalog_number, ca_store.ca_state, ca_ship.ca_state),
    (cp.cp_department, cp.cp_catalog_number)
  )
)
SELECT
  department,
  catalog_number,
  profit_comparison,
  catalog_net_profit,
  store_net_profit,
  catalog_quantity,
  store_quantity,
  catalog_distinct_bill_cust,
  store_distinct_cust,
  RANK() OVER (PARTITION BY department ORDER BY catalog_net_profit DESC) AS dept_catalog_profit_rank,
  ROW_NUMBER() OVER (ORDER BY (catalog_net_profit + store_net_profit) DESC) AS overall_sales_rank
FROM combined_sales
ORDER BY overall_sales_rank
LIMIT 100
