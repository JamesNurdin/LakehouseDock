WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
        AND cs.cs_order_number NOT IN (
            SELECT ws.ws_order_number
            FROM web_sales ws
            WHERE ws.ws_net_profit > 1000
        )
)
SELECT
    p.p_promo_name,
    cp.cp_type,
    CONCAT(p.p_promo_name, ' ', cp.cp_type) AS promo_type_desc,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count
FROM filtered_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    REGEXP_LIKE(cp.cp_description, '(?i)online|sale')
    AND cp.cp_type LIKE 'C%'
    AND REGEXP_EXTRACT(p.p_promo_name, '(\\w+)-\\d+$', 1) = 'PROMO'
GROUP BY
    p.p_promo_name,
    cp.cp_type,
    CONCAT(p.p_promo_name, ' ', cp.cp_type)
ORDER BY total_ext_sales DESC
LIMIT 100
