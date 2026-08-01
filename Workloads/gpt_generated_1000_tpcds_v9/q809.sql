WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        store.s_city,
        store.s_state,
        date_dim.d_year,
        date_dim.d_month_seq,
        store.s_store_id,
        CAST(regexp_extract(promotion.p_promo_name, 'Discount([0-9]+)', 1) AS integer) AS discount_code,
        concat(store.s_store_id, '-', CAST(date_dim.d_year AS varchar), '-', LPAD(CAST(date_dim.d_month_seq AS varchar), 2, '0')) AS store_year_month_tag
    FROM store_sales ss
    JOIN store ON ss.ss_store_sk = store.s_store_sk
    JOIN promotion ON ss.ss_promo_sk = promotion.p_promo_sk
    JOIN date_dim ON ss.ss_sold_date_sk = date_dim.d_date_sk
    WHERE
        store.s_store_name LIKE '%Outlet%'
        AND regexp_like(promotion.p_promo_name, 'Discount[0-9]+')
)
SELECT
    s_city,
    s_state,
    d_year,
    d_month_seq,
    discount_code,
    store_year_month_tag,
    COUNT(*) AS sales_count,
    SUM(ss_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM filtered_sales
GROUP BY
    s_city,
    s_state,
    d_year,
    d_month_seq,
    discount_code,
    store_year_month_tag
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
