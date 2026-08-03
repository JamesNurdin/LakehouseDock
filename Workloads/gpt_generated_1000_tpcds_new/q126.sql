WITH full_join AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        inv.inv_quantity_on_hand,
        it.i_item_sk,
        it.i_product_name,
        it.i_current_price,
        it.i_formulation,
        it.i_category,
        dd.d_year,
        dd.d_following_holiday,
        wp.wp_web_page_sk,
        wp.wp_char_count
    FROM inventory inv
    FULL OUTER JOIN item it
        ON inv.inv_item_sk = it.i_item_sk
    LEFT JOIN date_dim dd
        ON inv.inv_date_sk = dd.d_date_sk
    LEFT JOIN web_page wp
        ON dd.d_date_sk = wp.wp_creation_date_sk
),
filtered AS (
    SELECT *
    FROM full_join
    WHERE d_year = 2000
      AND d_following_holiday = 'N'
      AND i_formulation = 'snow1543775706017405'
      AND wp_char_count > 2000
),
agg AS (
    SELECT
        i_item_sk,
        i_product_name,
        d_year,
        SUM(COALESCE(inv_quantity_on_hand, 0)) AS total_quantity,
        AVG(i_current_price) AS avg_price,
        COUNT(DISTINCT wp_web_page_sk) AS distinct_pages
    FROM filtered
    GROUP BY i_item_sk, i_product_name, d_year
),
positive_items AS (
    SELECT i_item_sk, i_product_name, total_quantity
    FROM agg
    WHERE total_quantity > 0
),
zero_items AS (
    SELECT i_item_sk, i_product_name, total_quantity
    FROM agg
    WHERE total_quantity = 0
),
result_set AS (
    SELECT i_item_sk, i_product_name, total_quantity
    FROM positive_items
    EXCEPT
    SELECT i_item_sk, i_product_name, total_quantity
    FROM zero_items
)
SELECT i_item_sk, i_product_name, total_quantity
FROM result_set
ORDER BY total_quantity DESC
LIMIT 100
