WITH promo_item AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_item_id,
        i.i_current_price,
        p.p_promo_id,
        p.p_cost,
        p.p_response_target,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_discount_active,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        p.p_channel_catalog,
        p.p_channel_event,
        p.p_purpose
    FROM promotion p
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_start_date_sk BETWEEN 2450815 AND 2451088
),
agg AS (
    SELECT
        i_category,
        i_brand,
        COUNT(DISTINCT p_promo_id) AS promo_count,
        SUM(p_cost) AS total_promo_cost,
        AVG(p_response_target) AS avg_response_target,
        SUM(p_cost * p_response_target) / NULLIF(SUM(p_cost), 0) AS weighted_response,
        MAX(i_current_price) AS max_item_price,
        MIN(i_current_price) AS min_item_price
    FROM promo_item
    GROUP BY i_category, i_brand
    HAVING COUNT(DISTINCT p_promo_id) >= 5
),
cp_stats AS (
    SELECT
        COUNT(*) AS monthly_catalog_pages
    FROM catalog_page cp
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450815 AND 2451088
),
ws_stats AS (
    SELECT
        AVG(web_tax_percentage) AS avg_tax_ca
    FROM web_site ws
    WHERE ws.web_state = 'CA'
)
SELECT
    a.i_category,
    a.i_brand,
    a.promo_count,
    a.total_promo_cost,
    a.avg_response_target,
    a.weighted_response,
    a.max_item_price,
    a.min_item_price,
    RANK() OVER (ORDER BY a.total_promo_cost DESC) AS cost_rank,
    cp.monthly_catalog_pages,
    ws.avg_tax_ca
FROM agg a
CROSS JOIN cp_stats cp
CROSS JOIN ws_stats ws
ORDER BY a.total_promo_cost DESC
LIMIT 50
