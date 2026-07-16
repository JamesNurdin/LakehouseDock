WITH promo_agg AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_city AS s_city,
        s.s_state AS s_state,
        d_start.d_current_year AS store_year,
        d_start.d_current_month AS store_month,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        COUNT(p.p_promo_id) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_response_target) AS avg_response_target,
        MIN(date_diff('day', d_start.d_date, d_end.d_date)) AS min_promo_duration,
        MAX(date_diff('day', d_start.d_date, d_end.d_date)) AS max_promo_duration
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_start.d_current_year,
        d_start.d_current_month,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category
)
SELECT
    s_store_id,
    s_city,
    s_state,
    store_year,
    store_month,
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    promo_count,
    total_promo_cost,
    avg_response_target,
    min_promo_duration,
    max_promo_duration,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_promo_cost DESC) AS promo_cost_rank
FROM promo_agg
ORDER BY total_promo_cost DESC
LIMIT 100
