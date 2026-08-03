WITH agg_cr AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_order_number,
        SUM(cr.cr_return_quantity) AS total_qty,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_ship_mode_sk, cr.cr_order_number
)
SELECT
    i_cat.i_brand,
    sm.sm_type,
    promo_cat.p_promo_name,
    wp.wp_type,
    COUNT(DISTINCT agg_cr.cr_order_number) AS distinct_orders,
    SUM(agg_cr.total_qty) AS catalog_return_qty,
    SUM(agg_cr.total_amount) AS catalog_return_amount,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    AVG(promo_cat.p_cost) AS avg_promo_cost
FROM agg_cr
JOIN item i_cat
    ON agg_cr.cr_item_sk = i_cat.i_item_sk
JOIN ship_mode sm
    ON agg_cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion promo_cat
    ON i_cat.i_item_sk = promo_cat.p_item_sk
JOIN promotion promo_cat2
    ON i_cat.i_item_sk = promo_cat2.p_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i_cat.i_item_sk
JOIN item i_web
    ON wr.wr_item_sk = i_web.i_item_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN promotion promo_web
    ON i_web.i_item_sk = promo_web.p_item_sk
JOIN promotion promo_web2
    ON i_web.i_item_sk = promo_web2.p_item_sk
JOIN web_page wp2
    ON wr.wr_web_page_sk = wp2.wp_web_page_sk
WHERE promo_cat.p_cost > (
        SELECT MAX(p_cost)
        FROM promotion
        WHERE p_discount_active = 'Y'
    )
  AND agg_cr.cr_order_number NOT IN (
        SELECT wr_order_number
        FROM web_returns
        WHERE wr_return_quantity > 0
    )
GROUP BY i_cat.i_brand, sm.sm_type, promo_cat.p_promo_name, wp.wp_type
ORDER BY catalog_return_amount DESC
LIMIT 100
