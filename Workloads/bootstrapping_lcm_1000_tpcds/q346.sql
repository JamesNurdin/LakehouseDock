WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS discount_active_sum,
        SUM(CASE WHEN d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date THEN ss.ss_ext_sales_price ELSE 0 END) AS sales_during_promo,
        AVG(CASE WHEN d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date THEN ss.ss_ext_discount_amt END) AS avg_discount_during_promo,
        SUM(CASE WHEN d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date THEN 1 ELSE 0 END) AS days_with_active_promo
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    GROUP BY
        ss.ss_store_sk,
        d_sold.d_year,
        d_sold.d_month_seq
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_closed_date_sk,
        d_closed.d_year AS closed_year,
        d_closed.d_month_seq AS closed_month_seq
    FROM store s
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
),
pages_created_agg AS (
    SELECT
        d_c.d_year,
        d_c.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created
    FROM web_page wp
    JOIN date_dim d_c
        ON wp.wp_creation_date_sk = d_c.d_date_sk
    GROUP BY
        d_c.d_year,
        d_c.d_month_seq
),
pages_accessed_agg AS (
    SELECT
        d_a.d_year,
        d_a.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_accessed
    FROM web_page wp
    JOIN date_dim d_a
        ON wp.wp_access_date_sk = d_a.d_date_sk
    GROUP BY
        d_a.d_year,
        d_a.d_month_seq
)
SELECT
    si.s_store_id,
    si.s_city,
    si.s_state,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales,
    sa.total_profit,
    sa.avg_discount,
    sa.total_quantity,
    sa.promo_cnt,
    sa.discount_active_sum,
    sa.sales_during_promo,
    sa.avg_discount_during_promo,
    sa.days_with_active_promo,
    COALESCE(pc.pages_created, 0) AS pages_created,
    COALESCE(pa.pages_accessed, 0) AS pages_accessed,
    CASE
        WHEN si.closed_year = sa.d_year AND si.closed_month_seq = sa.d_month_seq THEN 'Closed'
        ELSE 'Open'
    END AS store_status
FROM sales_agg sa
JOIN store_info si
    ON sa.ss_store_sk = si.s_store_sk
LEFT JOIN pages_created_agg pc
    ON sa.d_year = pc.d_year
    AND sa.d_month_seq = pc.d_month_seq
LEFT JOIN pages_accessed_agg pa
    ON sa.d_year = pa.d_year
    AND sa.d_month_seq = pa.d_month_seq
ORDER BY
    si.s_store_id,
    sa.d_year,
    sa.d_month_seq
