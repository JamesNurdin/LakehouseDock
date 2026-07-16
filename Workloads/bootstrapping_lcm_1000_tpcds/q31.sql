WITH promo_metrics AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        p.p_cost,
        p.p_response_target,
        p.p_channel_tv,
        p.p_channel_email,
        (
            SELECT COUNT(DISTINCT s2.s_store_sk)
            FROM store s2
            JOIN date_dim d2 ON s2.s_closed_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN d_start.d_date AND d_end.d_date
        ) AS stores_closed_cnt,
        (
            SELECT AVG(s2.s_floor_space)
            FROM store s2
            JOIN date_dim d2 ON s2.s_closed_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN d_start.d_date AND d_end.d_date
        ) AS avg_store_floor_space,
        (
            SELECT COUNT(DISTINCT wp2.wp_web_page_sk)
            FROM web_page wp2
            JOIN date_dim d2 ON wp2.wp_creation_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN d_start.d_date AND d_end.d_date
        ) AS pages_created_cnt,
        (
            SELECT COUNT(DISTINCT wp2.wp_web_page_sk)
            FROM web_page wp2
            JOIN date_dim d2 ON wp2.wp_access_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN d_start.d_date AND d_end.d_date
        ) AS pages_accessed_cnt,
        (
            SELECT COUNT(DISTINCT ws2.web_site_sk)
            FROM web_site ws2
            JOIN date_dim d2 ON ws2.web_open_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN d_start.d_date AND d_end.d_date
        ) AS sites_opened_cnt,
        (
            SELECT COUNT(DISTINCT ws2.web_site_sk)
            FROM web_site ws2
            JOIN date_dim d2 ON ws2.web_close_date_sk = d2.d_date_sk
            WHERE d2.d_date BETWEEN d_start.d_date AND d_end.d_date
        ) AS sites_closed_cnt
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE p.p_cost > 0
)
SELECT
    pm.p_promo_id,
    pm.p_promo_name,
    pm.promo_start_date,
    pm.promo_end_date,
    pm.p_cost,
    pm.p_response_target,
    pm.p_channel_tv,
    pm.p_channel_email,
    pm.stores_closed_cnt,
    pm.avg_store_floor_space,
    pm.pages_created_cnt,
    pm.pages_accessed_cnt,
    pm.sites_opened_cnt,
    pm.sites_closed_cnt,
    pm.p_cost / NULLIF(pm.stores_closed_cnt, 0) AS cost_per_store_closed,
    ROW_NUMBER() OVER (ORDER BY pm.p_cost DESC) AS promo_cost_rank,
    ROW_NUMBER() OVER (ORDER BY pm.p_cost / NULLIF(pm.stores_closed_cnt, 0) DESC) AS rank_by_cost_per_store
FROM promo_metrics pm
ORDER BY pm.p_cost DESC
LIMIT 50
