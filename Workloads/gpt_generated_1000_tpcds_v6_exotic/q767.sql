WITH filtered_sales AS (
    SELECT cs.cs_warehouse_sk,
           cs.cs_ship_date_sk,
           cs.cs_list_price,
           cs.cs_quantity,
           cs.cs_ext_sales_price,
           cs.cs_ext_discount_amt,
           cs.cs_net_profit,
           cs.cs_bill_addr_sk,
           cs.cs_ship_addr_sk,
           cs.cs_item_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ship_date_sk BETWEEN 2450880 AND 2450905
      AND cs.cs_list_price > 50.00
      AND cs.cs_net_paid IS NOT NULL
),
 bill_addr AS (
    SELECT ca_address_sk, ca_state, ca_country
    FROM tpcds.customer_address
    WHERE ca_country = 'United States'
),
 ship_addr AS (
    SELECT ca_address_sk, ca_city AS ship_city, ca_state AS ship_state
    FROM tpcds.customer_address
),
 wh AS (
    SELECT w_warehouse_sk, w_warehouse_name, w_city, w_state
    FROM tpcds.warehouse
    WHERE w_city IN ('New York', 'Los Angeles', 'Chicago')
),
 inv AS (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.inventory
    GROUP BY inv_warehouse_sk
 )
SELECT
    wh.w_warehouse_name,
    wh.w_city,
    wh.w_state,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    SUM(fs.cs_quantity) AS total_quantity_sold,
    inv.total_on_hand AS inventory_on_hand,
    COUNT(CASE WHEN fs.cs_net_profit > 0 THEN 1 END) AS profitable_orders,
    COUNT(CASE WHEN fs.cs_net_profit <= 0 THEN 1 END) AS loss_orders,
    CASE WHEN SUM(fs.cs_ext_sales_price) > 100000 THEN 'High'
         WHEN SUM(fs.cs_ext_sales_price) BETWEEN 50000 AND 100000 THEN 'Medium'
         ELSE 'Low' END AS sales_category
FROM filtered_sales fs
JOIN bill_addr ba ON fs.cs_bill_addr_sk = ba.ca_address_sk
JOIN ship_addr sa ON fs.cs_ship_addr_sk = sa.ca_address_sk
JOIN wh ON fs.cs_warehouse_sk = wh.w_warehouse_sk
JOIN inv ON inv.inv_warehouse_sk = wh.w_warehouse_sk
GROUP BY
    wh.w_warehouse_name,
    wh.w_city,
    wh.w_state,
    inv.total_on_hand
ORDER BY total_sales DESC
LIMIT 100
