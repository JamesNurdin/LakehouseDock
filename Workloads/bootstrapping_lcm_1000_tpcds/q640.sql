WITH promotion_dates AS (
    SELECT
        p.p_promo_sk,
        p.p_cost,
        p.p_start_date_sk,
        p.p_end_date_sk,
        start_date.d_date AS start_date,
        end_date.d_date AS end_date,
        date_diff('day', start_date.d_date, end_date.d_date) AS promo_duration_days
    FROM promotion p
    JOIN date_dim start_date ON p.p_start_date_sk = start_date.d_date_sk
    JOIN date_dim end_date ON p.p_end_date_sk = end_date.d_date_sk
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.d_week_seq,
    agg.s_store_id,
    agg.s_city,
    agg.total_inventory,
    agg.distinct_pages_created,
    agg.distinct_pages_accessed,
    agg.avg_promo_cost,
    agg.avg_promo_duration,
    agg.weighted_inventory_ratio,
    RANK() OVER (PARTITION BY agg.d_year, agg.d_month_seq ORDER BY agg.total_inventory DESC) AS inventory_rank
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        s.s_store_id,
        s.s_city,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
        COUNT(DISTINCT wp_acc.wp_web_page_id) AS distinct_pages_accessed,
        AVG(promo.p_cost) AS avg_promo_cost,
        AVG(promo.promo_duration_days) AS avg_promo_duration,
        SUM(CASE WHEN promo.p_cost > 0 THEN i.inv_quantity_on_hand ELSE 0 END) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS weighted_inventory_ratio
    FROM date_dim d
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_page wp_acc ON wp_acc.wp_access_date_sk = d.d_date_sk
    JOIN promotion_dates promo ON promo.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND s.s_state = 'CA'
      AND promo.p_cost IS NOT NULL
    GROUP BY d.d_year, d.d_month_seq, d.d_week_seq, s.s_store_id, s.s_city
    HAVING SUM(i.inv_quantity_on_hand) > 500
) agg
ORDER BY agg.total_inventory DESC
LIMIT 50
