WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name,
        i.i_item_id,
        -- extract the first word of the description
        regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word_desc,
        -- flag whether the description contains any digit
        CASE WHEN regexp_like(i.i_item_desc, '\\d') THEN 'ContainsDigit' ELSE 'NoDigit' END AS digit_flag,
        -- create a readable label for the item
        concat(i.i_item_id, ' - ', i.i_product_name) AS item_label
    FROM item i
    WHERE regexp_like(i.i_item_desc, '(?i)steel|wood|plastic')
),
store_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'AM'
    GROUP BY sr.sr_item_sk
),
catalog_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'MORNING'
    GROUP BY cr.cr_item_sk
),
promo_agg AS (
    SELECT
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_name) AS distinct_promo_cnt
    FROM promotion p
    WHERE p.p_promo_name LIKE '%Discount%'
    GROUP BY p.p_item_sk
)
SELECT
    ir.i_category,
    ir.i_brand,
    ir.item_label,
    ir.first_word_desc,
    ir.digit_flag,
    COALESCE(sa.store_net_loss, 0) AS store_net_loss,
    COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(sa.store_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) AS total_net_loss,
    CASE
        WHEN COALESCE(sa.store_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_severity,
    COALESCE(pa.distinct_promo_cnt, 0) AS promo_count
FROM item_returns ir
LEFT JOIN store_agg sa ON ir.i_item_sk = sa.sr_item_sk
LEFT JOIN catalog_agg ca ON ir.i_item_sk = ca.cr_item_sk
LEFT JOIN promo_agg pa ON ir.i_item_sk = pa.p_item_sk
WHERE ir.digit_flag = 'NoDigit'
ORDER BY total_net_loss DESC, ir.i_category, ir.i_brand
LIMIT 100
