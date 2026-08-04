WITH
    sales_2022 AS (
        SELECT ss_store_sk,
               SUM(ss_net_paid) AS total_paid
        FROM store_sales
        JOIN date_dim ON ss_sold_date_sk = d_date_sk
        WHERE d_year = 2022
        GROUP BY ss_store_sk
    ),
    sales_2023 AS (
        SELECT ss_store_sk,
               SUM(ss_net_paid) AS total_paid
        FROM store_sales
        JOIN date_dim ON ss_sold_date_sk = d_date_sk
        WHERE d_year = 2023
        GROUP BY ss_store_sk
    ),
    store_2022 AS (
        SELECT s.s_store_id AS store_id
        FROM sales_2022 s2
        JOIN store s ON s2.ss_store_sk = s.s_store_sk
        WHERE s2.total_paid > 10000
    ),
    store_2023 AS (
        SELECT s.s_store_id AS store_id
        FROM sales_2023 s2
        JOIN store s ON s2.ss_store_sk = s.s_store_sk
        WHERE s2.total_paid > 10000
    ),
    warehouse_inventory AS (
        SELECT w.w_warehouse_id AS warehouse_id
        FROM inventory i
        TABLESAMPLE BERNOULLI (10)
        JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
        JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        WHERE i.inv_quantity_on_hand > 5000
    )
SELECT entity_type,
       entity_id
FROM (
    SELECT 'store' AS entity_type,
           store_id AS entity_id
    FROM store_2022
    INTERSECT
    SELECT 'store',
           store_id
    FROM store_2023
) AS both_years
UNION
SELECT 'store' AS entity_type,
       store_id AS entity_id
FROM store_2022
EXCEPT
SELECT 'store',
       store_id
FROM store_2023
UNION
SELECT 'warehouse' AS entity_type,
       warehouse_id AS entity_id
FROM warehouse_inventory
ORDER BY entity_type,
         entity_id
LIMIT 100
