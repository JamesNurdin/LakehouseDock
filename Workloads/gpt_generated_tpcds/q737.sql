WITH sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    GROUP BY cs.cs_catalog_page_sk
),
returns_agg AS (
    SELECT
        cr.cr_catalog_page_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    GROUP BY cr.cr_catalog_page_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_quantity_returned,
    s.total_quantity_sold,
    s.distinct_orders,
    (r.total_return_amount / NULLIF(s.total_sales, 0)) * 100 AS return_rate_percent
FROM catalog_page cp
JOIN sales_agg s
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN returns_agg r
    ON r.cr_catalog_page_sk = cp.cp_catalog_page_sk
ORDER BY s.total_sales DESC
LIMIT 10
