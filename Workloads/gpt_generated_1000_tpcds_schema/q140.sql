WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name,
        p.p_discount_active,
        p.p_cost
    FROM tpcds.item i
    FULL OUTER JOIN tpcds.promotion p
        ON i.i_item_sk = p.p_item_sk
)
SELECT
    COALESCE(ip.i_brand, 'Unknown') AS brand,
    COALESCE(ip.p_discount_active, 'N/A') AS discount_active,
    COUNT(DISTINCT ip.i_item_sk) AS distinct_items,
    SUM(COALESCE(ip.p_cost, 0)) AS total_promo_cost,
    MAX(regexp_extract(COALESCE(ip.i_item_desc, ''), '(\\d+)', 1)) AS max_numeric_in_desc,
    MIN(substr(COALESCE(ip.i_product_name, ''), 1, 10)) AS sample_name_prefix
FROM item_promo ip
WHERE
    ip.i_item_desc IS NOT NULL
    AND regexp_like(ip.i_item_desc, '[0-9]{3}')
    AND ip.p_discount_active IS NOT NULL
    AND ip.p_discount_active LIKE '%Active%'
GROUP BY
    COALESCE(ip.i_brand, 'Unknown'),
    COALESCE(ip.p_discount_active, 'N/A')
ORDER BY
    total_promo_cost DESC,
    brand
OFFSET 0
LIMIT 100
