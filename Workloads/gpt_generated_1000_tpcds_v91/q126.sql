WITH sales_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        'sales' AS source,
        SUM(ss.ss_ext_sales_price) AS amount,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        (SELECT COUNT(*)
         FROM catalog_returns cr
         WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
           AND cr.cr_returned_date_sk = d.d_date_sk) AS return_count,
        CAST(NULL AS BIGINT) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY c.c_customer_id, c.c_customer_sk, d.d_year, d.d_date_sk
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
returns_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        'returns' AS source,
        SUM(cr.cr_return_amount) AS amount,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items,
        CAST(NULL AS BIGINT) AS return_count,
        (SELECT COUNT(*)
         FROM store_sales ss2
         WHERE ss2.ss_customer_sk = c.c_customer_sk
           AND ss2.ss_sold_date_sk = d.d_date_sk) AS sales_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY c.c_customer_id, c.c_customer_sk, d.d_year, d.d_date_sk
    HAVING SUM(cr.cr_return_amount) > 500
),
combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
)
SELECT
    cd.customer_id,
    cd.year,
    cd.source,
    cd.amount,
    cd.distinct_items,
    cd.return_count,
    cd.sales_count,
    (COALESCE(cd.return_count, 0) + COALESCE(cd.sales_count, 0)) AS total_related
FROM combined cd
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss3
    JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
    JOIN customer c3 ON ss3.ss_customer_sk = c3.c_customer_sk
    WHERE c3.c_customer_id = cd.customer_id
      AND d3.d_year = cd.year
      AND ss3.ss_ext_sales_price > 0
)
ORDER BY cd.amount DESC, cd.customer_id
LIMIT 100
