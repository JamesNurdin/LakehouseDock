WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ext_sales_price,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
)
SELECT
    d.d_date,
    cp.cp_catalog_page_id,
    concat(cp.cp_catalog_page_id, '-', CAST(d.d_date AS varchar)) AS page_date_key,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    CASE
        WHEN ib.ib_upper_bound > 150000 THEN 'High'
        ELSE 'Medium'
    END AS income_bracket,
    regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word_desc,
    CASE
        WHEN regexp_like(cp.cp_description, '.*clearance.*') THEN 'Clearance'
        ELSE 'Regular'
    END AS desc_category
FROM filtered_sales fs
JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON fs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    cp.cp_type LIKE 'PROMO%'
    AND EXISTS (
        SELECT 1 FROM web_page wp
        WHERE wp.wp_web_page_id = cp.cp_catalog_page_id
          AND wp.wp_link_count > 5
          AND wp.wp_url LIKE '%sale%'
    )
GROUP BY
    d.d_date,
    cp.cp_catalog_page_id,
    cp.cp_description,
    ib.ib_upper_bound
HAVING
    SUM(fs.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
