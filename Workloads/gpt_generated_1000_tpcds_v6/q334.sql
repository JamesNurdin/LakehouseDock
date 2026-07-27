WITH sales AS (
    SELECT
        'sale' AS event_type,
        ss.ss_sold_date_sk AS date_key,
        i.i_item_id AS i_item_id,
        ss.ss_net_paid AS amount,
        CASE WHEN ss.ss_net_paid > 1000 THEN 'high' ELSE 'low' END AS amount_category,
        p.p_promo_name AS promo_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_paid > 0
      AND p.p_channel_demo = 'N'
),
returns AS (
    SELECT
        'return' AS event_type,
        cr.cr_returned_date_sk AS date_key,
        i.i_item_id AS i_item_id,
        cr.cr_return_amount AS amount,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'high' ELSE 'low' END AS amount_category,
        cc.cc_name AS promo_name
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_amount > 0
      AND cc.cc_state = 'CA'
),
combined AS (
    SELECT event_type, date_key, i_item_id, amount, amount_category, promo_name
    FROM sales
    UNION ALL
    SELECT event_type, date_key, i_item_id, amount, amount_category, promo_name
    FROM returns
)
SELECT
    d.event_type,
    d.date_key,
    d.i_item_id,
    d.amount,
    d.amount_category,
    d.promo_name,
    ROW_NUMBER() OVER (PARTITION BY d.i_item_id ORDER BY d.amount DESC) AS rank_by_amount
FROM (
    SELECT DISTINCT *
    FROM combined
) d
ORDER BY rank_by_amount
LIMIT 100
