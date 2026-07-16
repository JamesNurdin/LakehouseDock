WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        w.web_site_id,
        w.web_city,
        w.web_state,
        COUNT(p.p_promo_id) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_promo_duration_days,
        MIN(d_start.d_date) AS earliest_promo_start,
        MAX(d_end.d_date) AS latest_promo_end,
        MAX(d_web_close.d_date) AS website_close_date
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_start.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d_end.d_date_sk
    JOIN date_dim d_web_close ON w.web_close_date_sk = d_web_close.d_date_sk
    WHERE p.p_cost > 0
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        w.web_site_id,
        w.web_city,
        w.web_state
    HAVING SUM(p.p_cost) > 1000
)
SELECT
    agg.s_store_id,
    agg.s_city,
    agg.s_state,
    agg.web_site_id,
    agg.web_city,
    agg.web_state,
    agg.promo_count,
    agg.total_promo_cost,
    agg.avg_promo_duration_days,
    agg.earliest_promo_start,
    agg.latest_promo_end,
    agg.website_close_date,
    CASE
        WHEN agg.latest_promo_end <= agg.website_close_date THEN 'WithinSite'
        ELSE 'BeyondSite'
    END AS promo_vs_website_close_flag
FROM agg
ORDER BY agg.total_promo_cost DESC
LIMIT 100
