WITH
    sales_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            SUM(cs.cs_ext_sales_price) AS sales_amount
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2000
        )
        GROUP BY ROLLUP (i.i_category, d.d_year)
    ),
    returns_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            SUM(cr.cr_return_amount) AS return_amount
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE cr.cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2000
        )
        GROUP BY ROLLUP (i.i_category, d.d_year)
    ),
    common_keys AS (
        SELECT category, year
        FROM (
            SELECT DISTINCT category, year FROM sales_agg WHERE category IS NOT NULL
        )
        INTERSECT
        SELECT category, year FROM (
            SELECT DISTINCT category, year FROM returns_agg WHERE return_amount > 0
        )
    ),
    non_returned_items AS (
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2000
        )
        EXCEPT
        SELECT cr.cr_item_sk
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2000
        )
    )
SELECT
    ck.category,
    ck.year,
    SUM(sa.sales_amount) AS total_sales,
    SUM(ra.return_amount) AS total_returns,
    (SELECT COUNT(*) FROM non_returned_items) AS non_returned_item_count
FROM common_keys ck
LEFT JOIN sales_agg sa ON sa.category = ck.category AND sa.year = ck.year
LEFT JOIN returns_agg ra ON ra.category = ck.category AND ra.year = ck.year
GROUP BY ROLLUP (ck.category, ck.year)
ORDER BY ck.category NULLS LAST, ck.year NULLS LAST
LIMIT 100
