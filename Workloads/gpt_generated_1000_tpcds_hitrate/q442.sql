WITH sales_enriched AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_promo_sk,
        i.i_brand,
        i.i_category,
        i.i_item_desc,
        i.i_product_name,
        p.p_promo_name,
        cd.cd_gender,
        td.t_hour,
        -- extract the first numeric sequence from the item description
        regexp_extract(i.i_item_desc, '(\\d{2,})', 1) AS extracted_digits,
        -- categorize the net paid amount
        CASE
            WHEN cs.cs_net_paid > 1000 THEN 'high'
            WHEN cs.cs_net_paid BETWEEN 500 AND 1000 THEN 'medium'
            ELSE 'low'
        END AS sales_tier
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND p.p_promo_name LIKE '%Sale%'
)
SELECT
    brand_category,
    gender,
    sales_tier,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs_sold_date_sk) AS active_days,
    AVG(return_amount) AS avg_return_amount
FROM (
    SELECT
        CONCAT(se.i_brand, '-', se.i_category) AS brand_category,
        se.cd_gender AS gender,
        se.sales_tier,
        se.cs_quantity,
        se.cs_net_paid,
        se.cs_sold_date_sk,
        -- scalar sub‑query: average return amount for the same item across all catalog returns
        (SELECT AVG(cr.cr_return_amount)
         FROM catalog_returns cr
         WHERE cr.cr_item_sk = se.cs_item_sk) AS return_amount
    FROM sales_enriched se
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = se.cs_order_number
          AND cr2.cr_return_quantity > 0
          AND cr2.cr_item_sk = se.cs_item_sk
    )
) sub
GROUP BY GROUPING SETS (
    (brand_category, gender, sales_tier),
    (brand_category, gender),
    (brand_category)
)
ORDER BY total_net_paid DESC
LIMIT 100
