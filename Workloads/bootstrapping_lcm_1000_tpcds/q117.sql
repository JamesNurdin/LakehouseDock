WITH agg AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_quarter_name AS return_quarter,
        (d_ret.d_year * 100 + d_ret.d_month_seq) AS year_month_id,
        s.s_city AS store_city,
        w.w_state AS warehouse_state,
        ws.web_name AS website_name,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_quantity) AS total_quantity,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
           AND ws.web_close_date_sk = d_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_quarter_name,
        (d_ret.d_year * 100 + d_ret.d_month_seq),
        s.s_city,
        w.w_state,
        ws.web_name
)
SELECT
    return_year,
    return_quarter,
    year_month_id,
    store_city,
    warehouse_state,
    website_name,
    distinct_orders,
    total_net_loss,
    total_return_amount,
    avg_return_amount,
    total_fee,
    total_quantity,
    distinct_items_returned,
    CASE
        WHEN total_quantity > 100 THEN 'HIGH_VOLUME'
        ELSE 'LOW_VOLUME'
    END AS volume_category,
    total_return_amount / NULLIF(total_net_loss, 0) AS return_to_loss_ratio
FROM agg
ORDER BY return_year, return_quarter, store_city
