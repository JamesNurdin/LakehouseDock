WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_market_id,
        d_closure.d_year AS closure_year,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_response_target,
        d_start.d_month_seq AS promo_start_month,
        d_end.d_month_seq AS promo_end_month,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        SUM(wp.wp_image_count) AS total_image_count,
        AVG(wp.wp_char_count) AS avg_char_len,
        MAX(wp.wp_max_ad_count) AS max_ads
    FROM store s
    JOIN date_dim d_closure
        ON s.s_closed_date_sk = d_closure.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_closure.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_start.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE
        s.s_market_id IN (1, 2, 3)
        AND p.p_discount_active = 'Y'
        AND wp.wp_type = 'article'
        AND wp.wp_image_count > 0
        AND wp.wp_creation_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_market_id,
        d_closure.d_year,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_response_target,
        d_start.d_month_seq,
        d_end.d_month_seq
    HAVING
        SUM(wp.wp_image_count) > 10
)
SELECT
    agg.*,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.total_image_count DESC) AS promo_rank_by_images
FROM agg
ORDER BY agg.total_image_count DESC
LIMIT 100
