WITH sales_by_store AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_unique_customers,
        COUNT(DISTINCT i.i_brand) AS distinct_brands,
        COUNT(DISTINCT i.i_color) AS distinct_colors
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = ss.ss_ticket_number
    )
    GROUP BY d.d_year, i.i_category
),
sales_by_web AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_unique_customers,
        COUNT(DISTINCT i.i_brand) AS distinct_brands,
        COUNT(DISTINCT i.i_color) AS distinct_colors,
        addr_part
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    CROSS JOIN UNNEST(split(ca.ca_address_id, '-')) AS t(addr_part)
    GROUP BY d.d_year, i.i_category, addr_part
)
SELECT
    year,
    category,
    source,
    total_sales,
    unique_customers,
    distinct_brands,
    distinct_colors
FROM (
    SELECT
        d_year AS year,
        i_category AS category,
        'store' AS source,
        store_sales_total AS total_sales,
        store_unique_customers AS unique_customers,
        distinct_brands,
        distinct_colors
    FROM sales_by_store
    UNION ALL
    SELECT
        d_year AS year,
        i_category AS category,
        'web' AS source,
        web_sales_total AS total_sales,
        web_unique_customers AS unique_customers,
        distinct_brands,
        distinct_colors
    FROM sales_by_web
) q
ORDER BY year DESC, total_sales DESC
