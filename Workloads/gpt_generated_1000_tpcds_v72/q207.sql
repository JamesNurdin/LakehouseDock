WITH filtered_sales AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        p.p_promo_name,
        i.i_category,
        c.c_email_address,
        d.d_year,
        -- extract the first numeric block from the promotion name
        pc.promo_code
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_code
    ) AS pc
    WHERE d.d_year = 2020
      AND regexp_like(p.p_promo_name, '[0-9]{3,}')
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    i_category,
    promo_code,
    COUNT(*) AS sales_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    CONCAT('Promo ', promo_code, ': ', i_category) AS label
FROM filtered_sales
GROUP BY i_category, promo_code
ORDER BY total_sales DESC
LIMIT 100
