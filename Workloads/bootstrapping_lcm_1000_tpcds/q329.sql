WITH aggregated AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_manager,
        s.s_city,
        w.w_warehouse_name,
        w.w_state,
        d_store.d_quarter_name,
        d_store.d_year,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        SUM(p.p_cost) AS total_promo_cost,
        MIN(d_promo_end.d_date) AS earliest_promo_end_date,
        MAX(d_promo_end.d_date) AS latest_promo_end_date
    FROM store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_store.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON p.p_start_date_sk = d_store.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_store.d_quarter_name IS NOT NULL
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_manager,
        s.s_city,
        w.w_warehouse_name,
        w.w_state,
        d_store.d_quarter_name,
        d_store.d_year,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email
)
SELECT
    a.s_store_name,
    a.s_manager,
    a.s_city,
    a.w_warehouse_name,
    a.w_state,
    a.d_quarter_name,
    a.d_year,
    a.p_promo_name,
    a.p_channel_tv,
    a.p_channel_email,
    a.total_net_loss,
    a.total_return_qty,
    a.avg_return_amount,
    a.distinct_items_returned,
    a.total_promo_cost,
    a.earliest_promo_end_date,
    a.latest_promo_end_date,
    RANK() OVER (PARTITION BY a.d_quarter_name ORDER BY a.total_net_loss DESC) AS net_loss_rank_in_quarter
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100
