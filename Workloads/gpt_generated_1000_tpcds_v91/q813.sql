WITH
    cat_from_returns AS (
        SELECT DISTINCT i.i_category AS category
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
    ),
    cat_from_promos AS (
        SELECT DISTINCT i.i_category AS category
        FROM promotion p
        JOIN item i ON p.p_item_sk = i.i_item_sk
        WHERE regexp_like(p.p_promo_name, 'Discount|Promo|Sale')
    ),
    intersected_categories AS (
        SELECT category FROM cat_from_returns
        INTERSECT
        SELECT category FROM cat_from_promos
    )
SELECT
    i.i_category AS category,
    COALESCE(p.p_channel_email, 'N') AS channel_email,
    CASE 
        WHEN SUM(sr.sr_return_amt) > 10000 THEN 'High'
        WHEN SUM(sr.sr_return_amt) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    COUNT(*) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    ANY_VALUE(REGEXP_EXTRACT(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1)) AS extracted_code,
    ANY_VALUE(CONCAT(i.i_brand, ' - ', i.i_product_name)) AS brand_product
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
WHERE i.i_size LIKE '%large%'
  AND (p.p_channel_email = 'Y' OR p.p_channel_email = 'N')
  AND SUBSTRING(i.i_item_id FROM 1 FOR 4) = 'ITEM'
  AND i.i_category IN (SELECT category FROM intersected_categories)
GROUP BY GROUPING SETS (
    (i.i_category, p.p_channel_email),
    (i.i_category),
    ()
)
ORDER BY total_return_amt DESC
LIMIT 100
