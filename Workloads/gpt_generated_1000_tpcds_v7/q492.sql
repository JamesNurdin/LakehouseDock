WITH
  store_data AS (
    SELECT
      d.d_date AS sales_date,
      i.i_product_name,
      SUM(ss.ss_net_paid) AS total_sales,
      COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
      'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_date, i.i_product_name
  ),
  catalog_data AS (
    SELECT
      d.d_date AS sales_date,
      i.i_product_name,
      SUM(cs.cs_net_paid) AS total_sales,
      COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
      'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_date, i.i_product_name
  )
SELECT *
FROM store_data
UNION ALL
SELECT *
FROM catalog_data
ORDER BY sales_date DESC, total_sales DESC
