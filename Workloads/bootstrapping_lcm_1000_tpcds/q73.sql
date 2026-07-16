WITH inventory_summary AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(*) AS days_count
    FROM inventory
    GROUP BY inv_item_sk
),
promotion_summary AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        p.p_cost,
        p.p_response_target,
        p.p_start_date_sk,
        p.p_end_date_sk,
        date_diff('day', d_start.d_date, d_end.d_date) AS duration_days
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
)
SELECT
    d_start.d_date AS promo_start_date,
    d_end.d_date   AS promo_end_date,
    ps.p_promo_sk,
    ps.p_cost,
    ps.duration_days,
    s.s_store_id,
    s.s_city,
    s.s_state,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created,
    AVG(wp.wp_char_count) AS avg_web_page_char_count,
    MAX(ps.p_response_target) AS max_response_target,
    inv_sum.total_qty AS total_qty_for_item,
    (SUM(i.inv_quantity_on_hand) * 1.0) / inv_sum.days_count AS avg_daily_qty,
    SUM(ps.p_cost) OVER (PARTITION BY s.s_state) AS total_promo_cost_state
FROM promotion_summary ps
JOIN date_dim d_start ON ps.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end   ON ps.p_end_date_sk   = d_end.d_date_sk
JOIN inventory i      ON i.inv_date_sk = d_start.d_date_sk
JOIN store s          ON s.s_closed_date_sk = d_start.d_date_sk
JOIN web_page wp      ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN inventory_summary inv_sum ON inv_sum.inv_item_sk = i.inv_item_sk
WHERE s.s_state = 'CA'
  AND ps.p_cost > 0
  AND d_start.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_start.d_date,
    d_end.d_date,
    ps.p_promo_sk,
    ps.p_cost,
    ps.duration_days,
    s.s_store_id,
    s.s_city,
    s.s_state,
    inv_sum.total_qty,
    inv_sum.days_count
HAVING SUM(i.inv_quantity_on_hand) > 500
ORDER BY total_inventory_qty DESC
LIMIT 100
