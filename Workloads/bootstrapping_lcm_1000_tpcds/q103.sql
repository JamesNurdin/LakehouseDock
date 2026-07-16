WITH wp_stats AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        COUNT(DISTINCT wp_creation.wp_web_page_id) AS created_pages,
        COUNT(DISTINCT wp_access.wp_web_page_id) AS accessed_pages
    FROM date_dim d
    LEFT JOIN web_page wp_creation
        ON wp_creation.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk, d.d_date
)
SELECT
    s.s_store_id,
    s.s_city,
    d_store.d_date AS store_closed_date,
    d_store.d_year AS store_closed_year,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    p.p_discount_active,
    d_start.d_date AS promo_start_date,
    d_start.d_year AS promo_start_year,
    d_end.d_date AS promo_end_date,
    d_end.d_year AS promo_end_year,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    ws.created_pages,
    ws.accessed_pages,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d_start.d_date DESC) AS promo_rank_by_start_date
FROM promotion p
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN item i
    ON p.p_item_sk = i.i_item_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
LEFT JOIN wp_stats ws
    ON ws.d_date_sk = d_store.d_date_sk
WHERE d_store.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
ORDER BY d_start.d_date DESC, s.s_store_id
