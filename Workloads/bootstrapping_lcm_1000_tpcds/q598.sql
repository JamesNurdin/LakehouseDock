WITH monthly_metrics AS (
    SELECT
        date_trunc('month', d.d_date) AS month_start,
        i.i_category,
        i.i_brand,
        w.w_city AS warehouse_city,
        w.w_state AS warehouse_state,
        s.s_state AS store_state,
        CASE WHEN i.i_color = 'Red' THEN 'Red Items' ELSE 'Other Colors' END AS color_group,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_amount + cr.cr_return_tax + cr.cr_return_ship_cost) AS total_return_cost
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
      AND i.i_category IS NOT NULL
    GROUP BY
        date_trunc('month', d.d_date),
        i.i_category,
        i.i_brand,
        w.w_city,
        w.w_state,
        s.s_state,
        CASE WHEN i.i_color = 'Red' THEN 'Red Items' ELSE 'Other Colors' END
)
SELECT
    month_start,
    i_category,
    i_brand,
    warehouse_city,
    warehouse_state,
    store_state,
    color_group,
    return_cnt,
    total_quantity,
    total_return_amount,
    total_net_loss,
    avg_return_amount,
    total_fee,
    total_return_cost,
    total_return_amount / nullif(total_quantity, 0) AS avg_return_amount_per_quantity,
    total_net_loss / nullif(return_cnt, 0) AS avg_net_loss_per_return,
    ROW_NUMBER() OVER (PARTITION BY month_start ORDER BY total_net_loss DESC) AS net_loss_rank
FROM monthly_metrics
WHERE total_net_loss > 1000
ORDER BY month_start DESC, net_loss_rank
LIMIT 100
