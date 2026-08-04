WITH catalog_return_customers AS (
    SELECT DISTINCT cr_refunded_customer_sk AS customer_sk,
           cr_return_amount,
           cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_return_amount > 1000
),
web_return_customers AS (
    SELECT DISTINCT wr_refunded_customer_sk AS customer_sk,
           wr_return_amt,
           wr_returned_date_sk
    FROM web_returns
    WHERE wr_return_amt > 1000
),
common_return_customers AS (
    SELECT customer_sk
    FROM catalog_return_customers
    INTERSECT
    SELECT customer_sk
    FROM web_return_customers
),
sales_inventory AS (
    SELECT cs.cs_order_number,
           cs.cs_item_sk,
           cs.cs_warehouse_sk,
           cs.cs_quantity,
           inv.inv_quantity_on_hand
    FROM catalog_sales cs
    FULL OUTER JOIN inventory inv
        ON cs.cs_item_sk = inv.inv_item_sk
       AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
)
SELECT DISTINCT
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       'CommonReturn' AS source
FROM common_return_customers crc
JOIN customer c
      ON crc.customer_sk = c.c_customer_sk

UNION ALL

SELECT CAST(si.cs_order_number AS VARCHAR)      AS c_customer_id,
       CAST(si.cs_item_sk AS VARCHAR)           AS c_first_name,
       CAST(si.cs_warehouse_sk AS VARCHAR)      AS c_last_name,
       'SalesInventory' AS source
FROM sales_inventory si
WHERE si.cs_quantity > 10
LIMIT 100
