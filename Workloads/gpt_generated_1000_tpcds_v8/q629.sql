WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        bc.brand_category,
        w.word_count
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i ON cs.cs_item_sk = i.i_item_sk
        CROSS JOIN LATERAL (SELECT concat(i.i_brand, '-', i.i_category) AS brand_category) bc
        CROSS JOIN LATERAL (SELECT cardinality(split(i.i_item_desc, ' ')) AS word_count) w
    WHERE
        d.d_year = 2001
    GROUP BY
        cs.cs_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        bc.brand_category,
        w.word_count
),
returns_agg AS (
    SELECT
        cr.cr_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_return_customers,
        bc.brand_category,
        w.word_count
    FROM
        catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i ON cr.cr_item_sk = i.i_item_sk
        CROSS JOIN LATERAL (SELECT concat(i.i_brand, '-', i.i_category) AS brand_category) bc
        CROSS JOIN LATERAL (SELECT cardinality(split(i.i_item_desc, ' ')) AS word_count) w
    WHERE
        d.d_year = 2001
    GROUP BY
        cr.cr_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        bc.brand_category,
        w.word_count
)
SELECT
    item_id,
    brand_category,
    SUM(DISTINCT total_sales) AS distinct_sum_sales,
    SUM(DISTINCT total_returns) AS distinct_sum_returns,
    COUNT(DISTINCT distinct_customers) AS uniq_customers,
    COUNT(DISTINCT distinct_return_customers) AS uniq_return_customers,
    AVG(word_count) AS avg_word_count
FROM (
    SELECT
        i_item_id AS item_id,
        brand_category,
        total_sales,
        CAST(NULL AS decimal(7,2)) AS total_returns,
        distinct_customers,
        CAST(NULL AS integer) AS distinct_return_customers,
        word_count
    FROM sales_agg
    UNION
    SELECT
        i_item_id,
        brand_category,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        total_returns,
        CAST(NULL AS integer) AS distinct_customers,
        distinct_return_customers,
        word_count
    FROM returns_agg
) combined
GROUP BY
    item_id,
    brand_category
ORDER BY
    distinct_sum_sales DESC
LIMIT 100
