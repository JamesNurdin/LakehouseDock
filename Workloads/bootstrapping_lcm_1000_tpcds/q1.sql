WITH store_promo AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_quarter_name,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
        COUNT(DISTINCT w.wp_web_page_id) AS web_page_cnt,
        MAX(p.p_discount_active) AS discount_active_flag
    FROM date_dim d
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page w
        ON w.wp_creation_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN item i
        ON p.p_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, d.d_year, d.d_quarter_name
)
SELECT
    sp.s_store_id,
    sp.s_store_name,
    sp.s_state,
    sp.d_year,
    sp.d_quarter_name,
    sp.total_promo_cost,
    sp.avg_wholesale_cost,
    sp.promo_cnt,
    sp.web_page_cnt,
    CASE WHEN sp.discount_active_flag = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status,
    RANK() OVER (PARTITION BY sp.d_year ORDER BY sp.total_promo_cost DESC) AS yearly_store_rank
FROM store_promo sp
ORDER BY sp.total_promo_cost DESC
LIMIT 100
