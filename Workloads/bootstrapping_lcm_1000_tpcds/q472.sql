WITH promo_agg AS (
    SELECT
        s.s_division_name,
        s.s_city,
        ws.web_state,
        dd_start.d_year AS promo_start_year,
        dd_end.d_year AS promo_end_year,
        dd_close.d_year AS web_close_year,
        COUNT(DISTINCT i.i_item_id) AS num_items,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost,
        AVG(i.i_current_price - i.i_wholesale_cost) AS avg_margin,
        MAX(p.p_response_target) AS max_response_target,
        ROUND(SUM(p.p_cost) / NULLIF(COUNT(DISTINCT i.i_item_id), 0), 2) AS cost_per_item
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN date_dim dd_start ON p.p_start_date_sk = dd_start.d_date_sk
    JOIN date_dim dd_end ON p.p_end_date_sk = dd_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dd_end.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = dd_start.d_date_sk
    JOIN date_dim dd_close ON ws.web_close_date_sk = dd_close.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND dd_start.d_year = 2022
    GROUP BY
        s.s_division_name,
        s.s_city,
        ws.web_state,
        dd_start.d_year,
        dd_end.d_year,
        dd_close.d_year
)
SELECT
    pa.s_division_name,
    pa.s_city,
    pa.web_state,
    pa.promo_start_year,
    pa.promo_end_year,
    pa.web_close_year,
    pa.num_items,
    pa.total_promo_cost,
    pa.avg_promo_cost,
    pa.avg_margin,
    pa.max_response_target,
    pa.cost_per_item,
    ROW_NUMBER() OVER (PARTITION BY pa.s_division_name ORDER BY pa.total_promo_cost DESC) AS rank_within_division
FROM promo_agg pa
ORDER BY pa.total_promo_cost DESC
LIMIT 100
