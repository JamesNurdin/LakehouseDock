WITH
    sales AS (
        SELECT
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            SUM(cs.cs_net_paid_inc_tax) AS total_spent
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cs.cs_net_paid_inc_tax > 200.00
          AND cp.cp_type = 'Catalog'
        GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    ),
    web_sales AS (
        SELECT
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            SUM(cs.cs_net_paid_inc_tax) AS total_spent
        FROM web_page wp
        JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
        JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE wp.wp_image_count >= 4
          AND EXISTS (
              SELECT 1
              FROM catalog_page cp
              WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
                AND cp.cp_department = 'Books'
          )
        GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
    ),
    combined AS (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM web_sales
    )
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    total_spent,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_spent DESC) AS rn
FROM combined
ORDER BY total_spent DESC
LIMIT 100
