WITH sampled_items AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_product_name,
        i.i_manufact,
        i.i_rec_start_date,
        i.i_rec_end_date,
        p.p_cost
    FROM sampled_items i
    FULL OUTER JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE
        i.i_rec_start_date >= DATE '1999-01-01'
        AND i.i_rec_end_date <= DATE '2000-12-31'
        AND (i.i_manufact LIKE '%able%' OR i.i_manufact LIKE '%station%')
        AND NOT EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_cost > 5000
        )
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY i_current_price DESC) AS price_rank
    FROM joined
),
agg1 AS (
    SELECT
        i_brand || '-' || i_category AS brand_category,
        CASE WHEN i_current_price > 100 THEN 'High' ELSE 'Low' END AS price_category,
        SUM(p_cost) AS total_promo_cost,
        AVG(i_current_price) AS avg_price,
        MAX(price_rank) AS max_price_rank,
        CASE WHEN regexp_like(i_product_name, '[0-9]{2}') THEN true ELSE false END AS has_two_digits,
        (SELECT COUNT(*) FROM promotion p3 WHERE p3.p_item_sk = ranked.i_item_sk) AS promo_count
    FROM ranked
    GROUP BY
        i_brand,
        i_category,
        i_current_price,
        i_product_name,
        i_item_sk
)
SELECT *
FROM agg1
UNION
SELECT DISTINCT
    i.i_brand || '-' || i.i_category AS brand_category,
    'NoPromo' AS price_category,
    CAST(0 AS decimal(15,2)) AS total_promo_cost,
    i.i_current_price AS avg_price,
    NULL AS max_price_rank,
    false AS has_two_digits,
    0 AS promo_count
FROM item i
WHERE NOT EXISTS (
    SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk
)
  AND i.i_rec_start_date >= DATE '1999-01-01'
  AND i.i_rec_end_date <= DATE '2000-12-31'
ORDER BY brand_category, price_category
LIMIT 100
