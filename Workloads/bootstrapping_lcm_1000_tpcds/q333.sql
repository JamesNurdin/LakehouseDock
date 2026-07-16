WITH daily_store_returns AS (
    SELECT
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_market_manager,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        d_promo_end.d_date AS promo_end_date,
        wp.wp_url,
        wp.wp_type,
        wp.wp_max_ad_count,
        d_page_creation.d_date AS page_creation_date,
        d_page_access.d_date AS page_access_date,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page_creation
        ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    GROUP BY
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_market_manager,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        d_promo_end.d_date,
        wp.wp_url,
        wp.wp_type,
        wp.wp_max_ad_count,
        d_page_creation.d_date,
        d_page_access.d_date
)
SELECT
    dsr.return_date,
    dsr.d_year,
    dsr.d_month_seq,
    dsr.s_store_id,
    dsr.s_store_name,
    dsr.s_state,
    dsr.s_market_manager,
    dsr.p_promo_id,
    dsr.p_promo_name,
    dsr.p_cost,
    dsr.promo_end_date,
    dsr.wp_url,
    dsr.wp_type,
    dsr.wp_max_ad_count,
    dsr.page_creation_date,
    dsr.page_access_date,
    dsr.total_return_amount,
    dsr.total_return_qty,
    dsr.avg_return_tax,
    dsr.distinct_orders,
    CASE
        WHEN dsr.total_return_amount > 10000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY dsr.s_store_id ORDER BY dsr.total_return_amount DESC) AS store_return_rank,
    RANK() OVER (ORDER BY dsr.total_return_amount DESC) AS global_return_rank
FROM daily_store_returns dsr
ORDER BY dsr.total_return_amount DESC
LIMIT 100
