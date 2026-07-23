/*
Goal: Summarize sales metrics by catalog department and billing state, distinguishing high vs low sales categories for specific catalog page types and address filters, and combine results for quarterly and monthly pages.
*/
WITH bill_sales AS (
    SELECT
        cp.cp_department AS cp_department,
        ca.ca_state AS ca_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_bill_addr_sk IN (2121279, 1128744)
      AND cs.cs_ext_list_price > 8000
      AND cp.cp_type = 'quarterly'
      AND ca.ca_suite_number = 'Suite 70  '
      AND EXISTS (
          SELECT 1
          FROM customer_address ca_ship
          WHERE ca_ship.ca_address_sk = cs.cs_ship_addr_sk
            AND ca_ship.ca_state = 'CA'
      )
    GROUP BY cp.cp_department, ca.ca_state
),
ship_sales AS (
    SELECT
        cp.cp_department AS cp_department,
        ca.ca_state AS ca_state,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_bill_addr_sk NOT IN (2121279, 1128744)
      AND cs.cs_ext_list_price <= 8000
      AND cp.cp_type = 'monthly'
      AND ca.ca_suite_number = 'Suite 280 '
      AND EXISTS (
          SELECT 1
          FROM customer_address ca_ship
          WHERE ca_ship.ca_address_sk = cs.cs_ship_addr_sk
            AND ca_ship.ca_state = 'NY'
      )
    GROUP BY cp.cp_department, ca.ca_state
)
SELECT
    cp_department,
    ca_state,
    total_sales,
    avg_discount,
    order_count,
    sales_category
FROM bill_sales
UNION ALL
SELECT
    cp_department,
    ca_state,
    total_sales,
    avg_discount,
    order_count,
    sales_category
FROM ship_sales
ORDER BY total_sales DESC
LIMIT 100
