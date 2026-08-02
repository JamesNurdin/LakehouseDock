WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        CONCAT('Sales_', CAST(ss.ss_item_sk AS VARCHAR)) AS sales_label,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) > 1000 THEN 'High'
            ELSE 'Low'
        END AS sales_category
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_color LIKE '%re%'
        AND regexp_like(i.i_product_name, '.*[A-Z]{2,}.*')
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk, d.d_year
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        CONCAT('Return_', CAST(cr.cr_item_sk AS VARCHAR)) AS return_label,
        CASE
            WHEN SUM(cr.cr_return_amount) > 500 THEN 'Significant'
            ELSE 'Minor'
        END AS return_severity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (5002002, 1002001)
        AND regexp_extract(i.i_brand, '([0-9]+)', 1) IS NOT NULL
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk, d.d_year
)
SELECT
    COALESCE(sales_agg.ss_item_sk, returns_agg.cr_item_sk) AS item_sk,
    COALESCE(sales_agg.d_year, returns_agg.d_year) AS year,
    sales_agg.total_sales,
    returns_agg.total_return_amount,
    CASE
        WHEN sales_agg.total_sales IS NULL THEN returns_agg.total_return_amount
        WHEN returns_agg.total_return_amount IS NULL THEN sales_agg.total_sales
        ELSE sales_agg.total_sales - returns_agg.total_return_amount
    END AS net_sales_vs_returns,
    COALESCE(sales_agg.sales_label, returns_agg.return_label) AS label,
    COALESCE(sales_agg.sales_category, returns_agg.return_severity) AS category
FROM sales_agg
FULL OUTER JOIN returns_agg
    ON sales_agg.ss_item_sk = returns_agg.cr_item_sk
    AND sales_agg.ss_sold_date_sk = returns_agg.cr_returned_date_sk
ORDER BY net_sales_vs_returns DESC
LIMIT 100
