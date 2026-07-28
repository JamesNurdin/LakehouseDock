/*
Goal: Identify the top‑selling customers for each TV‑channel promotion, summarising sales and discount metrics while applying string‑based filters on promotion names and product descriptions.
*/
WITH filtered_sales AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        c.c_first_name,
        c.c_last_name,
        i.i_category,
        i.i_product_name,
        i.i_item_desc,
        p.p_promo_name,
        p.p_channel_tv,
        cc.cc_name AS call_center_name,
        row_number() OVER (PARTITION BY cs.cs_promo_sk ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE regexp_like(p.p_promo_name, '^Promo[0-9]{3}')
      AND p.p_channel_tv = 'Y'
      AND i.i_product_name LIKE '%Premium%'
)
SELECT
    fs.cs_promo_sk,
    p.p_promo_name,
    i.i_category,
    COUNT(DISTINCT fs.cs_bill_customer_sk) AS unique_customers,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    CASE
        WHEN SUM(fs.cs_ext_sales_price) > 100000 THEN 'High'
        WHEN SUM(fs.cs_ext_sales_price) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_band,
    CONCAT(fs.c_first_name, ' ', fs.c_last_name) AS customer_name,
    regexp_extract(fs.i_item_desc, '[0-9]+') AS extracted_item_code,
    (SELECT avg(cs.cs_ext_discount_amt) FROM catalog_sales cs) AS overall_avg_discount,
    fs.call_center_name
FROM filtered_sales fs
JOIN promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
JOIN item i
    ON p.p_item_sk = i.i_item_sk
WHERE fs.rn <= 3
GROUP BY
    fs.cs_promo_sk,
    p.p_promo_name,
    i.i_category,
    fs.c_first_name,
    fs.c_last_name,
    regexp_extract(fs.i_item_desc, '[0-9]+'),
    fs.call_center_name
ORDER BY total_sales DESC
LIMIT 100
