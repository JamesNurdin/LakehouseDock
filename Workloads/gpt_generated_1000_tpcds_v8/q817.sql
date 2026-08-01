/*
Goal: Compare promotional performance across catalog and store sales, identify high‑profit promotions, exclude certain promotion keys using EXCEPT, and expand a derived array per promotion while applying window ranking and existence checks.
*/
WITH promo_sales_cat AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_net_profit) AS cat_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn_cat,
        ARRAY[CAST(p.p_promo_sk AS varchar), CAST(p.p_cost AS varchar)] AS promo_arr
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 10
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_cost
),
promo_sales_store AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 8000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn_store,
        ARRAY[CAST(p.p_promo_sk AS varchar), CAST(p.p_cost AS varchar)] AS promo_arr
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_quantity > 5
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_cost
),
promo_keys_to_exclude AS (
    SELECT p_sk FROM (
        SELECT cs.cs_promo_sk AS p_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 30
    )
    EXCEPT
    SELECT ss.ss_promo_sk AS p_sk
    FROM store_sales ss
    WHERE ss.ss_quantity < 2
)
SELECT
    u.p_promo_id,
    u.total_sales,
    u.profit_level,
    u.rn,
    arr_element AS promo_arr_element
FROM (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        cat_sales AS total_sales,
        profit_level,
        rn_cat AS rn,
        promo_arr
    FROM promo_sales_cat p
    WHERE p.p_promo_sk NOT IN (SELECT p_sk FROM promo_keys_to_exclude)
    UNION
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        store_sales AS total_sales,
        profit_level,
        rn_store AS rn,
        promo_arr
    FROM promo_sales_store p
    WHERE p.p_promo_sk NOT IN (SELECT p_sk FROM promo_keys_to_exclude)
) u
CROSS JOIN UNNEST(u.promo_arr) AS t(arr_element)
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = u.p_promo_sk
      AND p2.p_discount_active = 'Y'
)
ORDER BY u.total_sales DESC, u.rn
LIMIT 100
