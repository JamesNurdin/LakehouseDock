WITH sales_by_customer AS (
    SELECT
        cs.cs_bill_customer_sk,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_country,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_count,
        MAX(cp.cp_description) AS any_description,
        MAX(cp.cp_type) AS any_type
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        d.d_year = 2020
        AND regexp_like(cp.cp_description, '[A-Z]{3}[0-9]{2}')
        AND cp.cp_type LIKE 'C%'
        AND c.c_first_name LIKE 'M%'
        AND ca.ca_city LIKE 'San%'
    GROUP BY
        cs.cs_bill_customer_sk,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_country,
        d.d_year
)
SELECT
    sbc.c_salutation || ' ' || sbc.c_first_name || ' ' || sbc.c_last_name AS full_name,
    sbc.ca_city,
    sbc.ca_country,
    sbc.d_year,
    sbc.total_net_paid,
    sbc.order_count,
    regexp_extract(sbc.any_description, '([A-Z]{3}[0-9]{2})', 1) AS extracted_code,
    substring(sbc.c_first_name, 1, 1) AS first_initial,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM inventory i
            JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
            JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
            WHERE i.inv_quantity_on_hand > 0
              AND w.w_warehouse_id = 'W_001'
              AND d2.d_year = sbc.d_year
        ) THEN 'In Stock'
        ELSE 'Out of Stock'
    END AS inventory_status
FROM
    sales_by_customer sbc
ORDER BY
    sbc.total_net_paid DESC
LIMIT 100
