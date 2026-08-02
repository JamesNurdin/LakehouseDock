WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_catalog_page_sk,
        cp.cp_type,
        cp.cp_description,
        d.d_year,
        substring(cp.cp_description, 1, 10) AS short_desc
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        regexp_like(cp.cp_description, '\\d{3}')
        AND cp.cp_description LIKE '%special%'
        AND d.d_year > (
            SELECT min(d2.d_year)
            FROM tpcds.date_dim d2
            WHERE d2.d_fy_week_seq = 1
        )
)
SELECT
    cp_type,
    count(*) AS orders,
    sum(cs_ext_sales_price) AS total_sales,
    avg(cs_ext_sales_price) AS avg_sales,
    min(short_desc) AS example_short_desc
FROM filtered_sales
GROUP BY cp_type
ORDER BY total_sales DESC
LIMIT 100
