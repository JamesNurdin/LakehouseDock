WITH enriched_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        d.d_year,
        cp.cp_description,
        p.p_promo_name,
        p.p_discount_active,
        -- Extract product category from the description using a regex
        regexp_extract(cp.cp_description, '(?i)(Electronics|Clothing|Books|Home|Toys)', 1) AS product_category,
        -- Classify promotion status using CASE
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'NoDiscount' END AS promo_status,
        -- Classify order size using CASE (not used in final aggregation, shown as example of CASE)
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS order_type,
        -- Concatenated segment string for later use
        CONCAT(regexp_extract(cp.cp_description, '(?i)(Electronics|Clothing|Books|Home|Toys)', 1), '-', CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'NoDiscount' END) AS segment
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND regexp_like(cp.cp_description, '(?i)(Electronics|Clothing|Books|Home|Toys)')
)

SELECT
    es.d_year AS year,
    CONCAT(es.product_category, '-', es.promo_status) AS segment,
    COUNT(DISTINCT es.cs_order_number) AS num_orders,
    SUM(es.cs_net_profit) AS total_profit,
    AVG(es.cs_net_profit) AS avg_profit,
    CASE WHEN SUM(es.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_flag
FROM enriched_sales es
WHERE
    es.product_category = 'Electronics'
    AND es.promo_status = 'Discount'
    AND es.p_promo_name LIKE '%Summer%'
GROUP BY
    es.d_year,
    es.product_category,
    es.promo_status,
    CONCAT(es.product_category, '-', es.promo_status)

UNION

SELECT
    es.d_year AS year,
    CONCAT(es.product_category, '-', es.promo_status) AS segment,
    COUNT(DISTINCT es.cs_order_number) AS num_orders,
    SUM(es.cs_net_profit) AS total_profit,
    AVG(es.cs_net_profit) AS avg_profit,
    CASE WHEN SUM(es.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_flag
FROM enriched_sales es
WHERE
    es.product_category = 'Clothing'
    AND es.promo_status = 'NoDiscount'
    AND es.p_promo_name LIKE '%Clearance%'
GROUP BY
    es.d_year,
    es.product_category,
    es.promo_status,
    CONCAT(es.product_category, '-', es.promo_status)

ORDER BY total_profit DESC
LIMIT 100
