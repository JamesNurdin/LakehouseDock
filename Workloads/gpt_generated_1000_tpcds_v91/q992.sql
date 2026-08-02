WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_brand,
        i_brand_id,
        i_category,
        i_category_id,
        i_units,
        i_container,
        i_item_desc,
        i_rec_start_date,
        i_rec_end_date
    FROM item
    TABLESAMPLE BERNOULLI (10)
    WHERE i_units LIKE '%Bunch%'
      AND i_container <> 'Unknown'
      AND regexp_like(i_item_desc, '\\b[0-9]{3}\\b')
)
SELECT
    CONCAT(fi.i_brand, ' (', CAST(fi.i_brand_id AS VARCHAR), ')') AS brand_label,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(SUBSTRING(fi.i_item_desc FROM 1 FOR 30)) AS short_desc
FROM filtered_items fi
JOIN promotion p
    ON p.p_item_sk = fi.i_item_sk
WHERE regexp_like(p.p_channel_details, '(?i)excellent|high')
  AND p.p_discount_active = 'Y'
  AND EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_item_sk = fi.i_item_sk
        AND p2.p_cost > 500
  )
GROUP BY
    fi.i_brand,
    fi.i_brand_id
HAVING SUM(p.p_cost) > (
    SELECT AVG(total_cost)
    FROM (
        SELECT SUM(p3.p_cost) AS total_cost
        FROM promotion p3
        JOIN item i3 ON p3.p_item_sk = i3.i_item_sk
        WHERE i3.i_category_id = 1
    ) sub
)
ORDER BY total_promo_cost DESC
LIMIT 100
