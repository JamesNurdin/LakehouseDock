WITH agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_page_number,
        d_cp_start.d_date AS catalog_start_date,
        d_cp_end.d_date AS catalog_end_date,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        d_store_closed.d_date AS store_closed_date,
        ws.web_name AS web_name,
        ws.web_state AS web_state,
        d_ws_open.d_date AS site_open_date,
        d_ws_close.d_date AS site_close_date,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        COALESCE(SUM(p.p_cost), 0) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost,
        date_diff('day', d_cp_start.d_date, d_cp_end.d_date) AS catalog_page_days
    FROM store s
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    CROSS JOIN catalog_page cp
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    CROSS JOIN web_site ws
    JOIN date_dim d_ws_open
        ON ws.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk <= cp.cp_end_date_sk
        AND p.p_end_date_sk >= cp.cp_start_date_sk
    LEFT JOIN date_dim d_p_start
        ON p.p_start_date_sk = d_p_start.d_date_sk
    LEFT JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
    WHERE d_cp_start.d_year = 2023
        AND s.s_state = 'CA'
        AND ws.web_state = 'CA'
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_page_number,
        d_cp_start.d_date,
        d_cp_end.d_date,
        s.s_store_name,
        s.s_state,
        d_store_closed.d_date,
        ws.web_name,
        ws.web_state,
        d_ws_open.d_date,
        d_ws_close.d_date
    HAVING COUNT(DISTINCT p.p_promo_id) > 0
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_page_number,
    catalog_start_date,
    catalog_end_date,
    s_store_name,
    s_state,
    store_closed_date,
    web_name,
    web_state,
    site_open_date,
    site_close_date,
    promo_count,
    total_promo_cost,
    avg_promo_cost,
    catalog_page_days,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_promo_cost DESC) AS store_rank_by_cost
FROM agg
ORDER BY total_promo_cost DESC
LIMIT 50
