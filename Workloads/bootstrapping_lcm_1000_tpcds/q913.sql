WITH return_detail AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dd.d_year,
        dd.d_moy AS month_num,
        i.i_category,
        i.i_class,
        sm.sm_type AS ship_mode_type,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN date_dim dd
        ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s
        ON s.s_closed_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2020 AND 2023
),
agg_by_store_month AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        d_year,
        month_num,
        i_category,
        i_class,
        ship_mode_type,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS num_returns
    FROM return_detail
    GROUP BY
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        d_year,
        month_num,
        i_category,
        i_class,
        ship_mode_type
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, month_num ORDER BY total_net_loss DESC) AS net_loss_rank,
        LAG(total_net_loss) OVER (PARTITION BY s_store_sk ORDER BY d_year, month_num) AS prev_month_net_loss,
        total_net_loss - LAG(total_net_loss) OVER (PARTITION BY s_store_sk ORDER BY d_year, month_num) AS net_loss_change
    FROM agg_by_store_month
)
SELECT
    d_year,
    month_num,
    s_store_name,
    s_city,
    s_state,
    i_category,
    i_class,
    ship_mode_type,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    num_returns,
    net_loss_rank,
    prev_month_net_loss,
    net_loss_change
FROM ranked
WHERE net_loss_change IS NOT NULL
ORDER BY d_year DESC, month_num DESC, net_loss_rank ASC
