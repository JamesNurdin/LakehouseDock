WITH joined_data AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
                     AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND cd.cd_gender = 'M'
      AND cd.cd_dep_college_count >= 3
      AND w.w_state = 'CA'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, d.d_year, d.d_month_seq
),
agg_by_warehouse AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        AVG(total_net_loss) AS avg_monthly_loss,
        SUM(total_qty_on_hand) AS sum_qty_on_hand
    FROM joined_data
    GROUP BY w_warehouse_sk, w_warehouse_name
    HAVING AVG(total_net_loss) > 1000
)
SELECT
    w_warehouse_sk,
    w_warehouse_name,
    avg_monthly_loss,
    sum_qty_on_hand,
    RANK() OVER (ORDER BY avg_monthly_loss DESC) AS loss_rank
FROM agg_by_warehouse
ORDER BY loss_rank
