WITH recent_customers AS (
    SELECT
        c_customer_sk,
        concat(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        c_email_address
    FROM tpcds.customer
    WHERE regexp_like(c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c_last_name LIKE 'S%'
)
SELECT *
FROM (
    SELECT
        'Catalog' AS source,
        warehouse.w_state AS region,
        recent_customers.full_name,
        sum(catalog_sales.cs_net_paid) AS total_sales
    FROM tpcds.catalog_sales
    JOIN recent_customers
        ON catalog_sales.cs_bill_customer_sk = recent_customers.c_customer_sk
    JOIN tpcds.warehouse
        ON catalog_sales.cs_warehouse_sk = warehouse.w_warehouse_sk
    WHERE regexp_like(warehouse.w_warehouse_name, '.*DC.*')
    GROUP BY
        warehouse.w_state,
        recent_customers.full_name
    UNION ALL
    SELECT
        'Web' AS source,
        ship_mode.sm_carrier AS region,
        recent_customers.full_name,
        sum(web_sales.ws_net_paid) AS total_sales
    FROM tpcds.web_sales
    JOIN recent_customers
        ON web_sales.ws_bill_customer_sk = recent_customers.c_customer_sk
    JOIN tpcds.ship_mode
        ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    WHERE ship_mode.sm_type LIKE '%AIR%'
      AND regexp_extract(ship_mode.sm_carrier, '(Express|Standard)$') = 'Express'
    GROUP BY
        ship_mode.sm_carrier,
        recent_customers.full_name
) combined
ORDER BY total_sales DESC
LIMIT 100
