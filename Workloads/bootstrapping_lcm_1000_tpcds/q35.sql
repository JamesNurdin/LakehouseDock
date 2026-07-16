WITH return_metrics AS (
    SELECT
        d.d_year,
        d.d_current_month,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        s.s_state,
        COUNT(DISTINCT cr.cr_order_number) AS num_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_fee) AS total_fee,
        AVG(i.i_current_price) AS avg_item_price,
        SUM(cr.cr_return_amount - cr.cr_fee) AS net_return_minus_fee,
        CASE
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High'
            WHEN SUM(cr.cr_net_loss) > 100 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE cr.cr_net_loss > 0
    GROUP BY
        d.d_year,
        d.d_current_month,
        i.i_category,
        i.i_brand,
        r.r_reason_desc,
        s.s_state
)
SELECT
    rm.d_year,
    rm.d_current_month,
    rm.i_category,
    rm.i_brand,
    rm.r_reason_desc,
    rm.s_state,
    rm.num_orders,
    rm.total_return_amount,
    rm.total_net_loss,
    rm.avg_return_quantity,
    rm.total_fee,
    rm.avg_item_price,
    rm.net_return_minus_fee,
    rm.loss_category,
    ROW_NUMBER() OVER (PARTITION BY rm.d_year ORDER BY rm.total_net_loss DESC) AS net_loss_rank_year
FROM return_metrics rm
ORDER BY rm.total_net_loss DESC
LIMIT 200
