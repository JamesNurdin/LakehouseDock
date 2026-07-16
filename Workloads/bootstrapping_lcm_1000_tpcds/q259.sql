SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    i.i_category,
    i.i_brand,
    d_start.d_year AS promo_year,
    COUNT(p.p_promo_id) AS promo_cnt,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(d_start.d_date) AS first_promo_start,
    MAX(d_end.d_date) AS last_promo_end,
    DATE_DIFF('day', MIN(d_start.d_date), MAX(d_end.d_date)) AS promo_campaign_span_days,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(p.p_cost) DESC) AS store_rank
FROM promotion p
INNER JOIN item i ON p.p_item_sk = i.i_item_sk
INNER JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
INNER JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
INNER JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_store_id,
    i.i_category,
    i.i_brand,
    d_start.d_year
ORDER BY store_rank
LIMIT 100
