WITH full_join AS (
    SELECT
        promotion.p_promo_sk,
        promotion.p_promo_id,
        promotion.p_channel_email,
        promotion.p_channel_catalog,
        promotion.p_discount_active,
        web_sales.ws_sold_date_sk,
        web_sales.ws_ext_sales_price,
        web_sales.ws_quantity,
        web_sales.ws_sales_price,
        web_sales.ws_ship_mode_sk
    FROM tpcds.promotion AS promotion
    FULL OUTER JOIN tpcds.web_sales AS web_sales
        ON web_sales.ws_promo_sk = promotion.p_promo_sk
),
filtered AS (
    SELECT *
    FROM full_join fj
    WHERE
        fj.p_discount_active = 'Y'                       -- predicate 1
        AND fj.p_channel_email = 'N'                     -- predicate 2
        AND fj.p_channel_catalog = 'N'                   -- predicate 3
        AND fj.ws_quantity >= 10                         -- predicate 4
        AND fj.ws_sales_price BETWEEN 30 AND 150         -- predicate 5
        AND fj.ws_ship_mode_sk IN (3, 11, 14)            -- predicate 6
        AND NOT EXISTS (                                 -- anti‑join
            SELECT 1
            FROM tpcds.web_sales ws_ex
            WHERE ws_ex.ws_promo_sk = fj.p_promo_sk
              AND ws_ex.ws_sales_price > 200
        )
),
with_lateral AS (
    SELECT
        f.*,
        la.high_qty_cnt
    FROM filtered f
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS high_qty_cnt
        FROM tpcds.web_sales ws_l
        WHERE ws_l.ws_promo_sk = f.p_promo_sk
          AND ws_l.ws_quantity > 50
    ) la
),
grouped AS (
    SELECT
        p_promo_id,
        p_channel_email,
        SUM(ws_ext_sales_price) AS sum_sales,
        COUNT(*) AS cnt_sales,
        AVG(high_qty_cnt) AS avg_high_qty_cnt
    FROM with_lateral
    GROUP BY p_promo_id, p_channel_email
),
final_agg AS (
    SELECT
        g.p_promo_id,
        g.p_channel_email,
        g.sum_sales,
        g.cnt_sales,
        g.avg_high_qty_cnt,
        ROW_NUMBER() OVER (PARTITION BY g.p_channel_email ORDER BY g.sum_sales DESC) AS channel_rank
    FROM grouped g
    WHERE g.sum_sales > 1000
)
SELECT
    f.p_promo_id,
    f.p_channel_email,
    f.sum_sales,
    f.cnt_sales,
    f.avg_high_qty_cnt,
    f.channel_rank
FROM final_agg f
WHERE f.p_promo_id IN (
    SELECT p_promo_id FROM tpcds.promotion WHERE p_channel_email = 'N'
    INTERSECT
    SELECT p_promo_id FROM tpcds.promotion WHERE p_discount_active = 'Y'
)
ORDER BY f.sum_sales DESC
LIMIT 100
