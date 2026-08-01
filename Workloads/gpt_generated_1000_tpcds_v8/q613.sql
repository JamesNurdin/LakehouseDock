WITH eligible_items AS (
    SELECT DISTINCT ss.ss_item_sk, ss.ss_store_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(i.i_item_desc, '(?i)coffee')
      AND s.s_zip LIKE '3%'
      AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_item_sk = ss.ss_item_sk
              AND sr.sr_store_sk = s.s_store_sk
              AND sr.sr_return_quantity > 0
        )
),
catalog_items AS (
    SELECT DISTINCT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
),
filtered_items AS (
    SELECT ei.ss_item_sk
    FROM eligible_items ei
    EXCEPT
    SELECT ci.cs_item_sk
    FROM catalog_items ci
)
SELECT
    s.s_state,
    i.i_category,
    MAX(CONCAT(i.i_brand, ' ', i.i_product_name)) AS product_label,
    MAX(REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1)) AS first_word_desc,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS num_transactions
FROM store_sales ss
JOIN filtered_items fi ON ss.ss_item_sk = fi.ss_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND s.s_zip LIKE '3%'
GROUP BY ROLLUP (s.s_state, i.i_category)
ORDER BY s.s_state NULLS LAST, i.i_category NULLS LAST, total_net_profit DESC
OFFSET 10 LIMIT 100
