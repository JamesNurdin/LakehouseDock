WITH promo_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        start_date.d_year               AS store_close_year,
        i.i_brand,
        COUNT(DISTINCT p.p_promo_id)    AS promotion_count,
        SUM(p.p_cost)                   AS total_promotion_cost,
        AVG(p.p_cost)                   AS avg_promotion_cost,
        AVG(i.i_wholesale_cost)         AS avg_item_wholesale_cost,
        SUM(date_diff('day', start_date.d_date, end_date.d_date)) AS total_promo_duration_days,
        AVG(date_diff('day', start_date.d_date, end_date.d_date)) AS avg_promo_duration_days,
        COUNT(DISTINCT i.i_item_id)     AS distinct_items_promoted,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS discount_active_count
    FROM promotion p
    JOIN date_dim start_date
        ON p.p_start_date_sk = start_date.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = start_date.d_date_sk
    JOIN date_dim end_date
        ON p.p_end_date_sk = end_date.d_date_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        start_date.d_year,
        i.i_brand
)
SELECT
    pa.s_store_id,
    pa.s_store_name,
    pa.s_city,
    pa.store_close_year,
    pa.i_brand,
    pa.promotion_count,
    pa.total_promotion_cost,
    pa.avg_promotion_cost,
    pa.avg_item_wholesale_cost,
    pa.total_promo_duration_days,
    pa.avg_promo_duration_days,
    pa.distinct_items_promoted,
    pa.discount_active_count,
    ROW_NUMBER() OVER (PARTITION BY pa.s_store_id ORDER BY pa.total_promotion_cost DESC) AS brand_rank_by_total_cost
FROM promo_agg pa
ORDER BY
    pa.total_promotion_cost DESC,
    pa.s_store_id
