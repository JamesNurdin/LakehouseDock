WITH daily_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS daily_quantity,
        SUM(ss.ss_ext_sales_price) AS daily_sales
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    ds.ss_sold_date_sk,
    ds.daily_quantity,
    LAG(ds.daily_quantity) OVER (PARTITION BY ds.ss_item_sk ORDER BY ds.ss_sold_date_sk) AS prev_daily_quantity,
    CASE
        WHEN LAG(ds.daily_quantity) OVER (PARTITION BY ds.ss_item_sk ORDER BY ds.ss_sold_date_sk) IS NULL THEN NULL
        WHEN ds.daily_quantity > LAG(ds.daily_quantity) OVER (PARTITION BY ds.ss_item_sk ORDER BY ds.ss_sold_date_sk) THEN 'INCREASE'
        ELSE 'NO_INCREASE'
    END AS sales_trend_flag,
    CASE
        WHEN p.p_promo_sk IS NOT NULL AND ds.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk THEN 'PROMO_ACTIVE'
        ELSE 'NO_PROMO'
    END AS promo_status,
    COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand
FROM daily_sales ds
JOIN item i ON ds.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
WHERE ds.daily_quantity > 0
ORDER BY i.i_item_id, ds.ss_sold_date_sk
LIMIT 100
