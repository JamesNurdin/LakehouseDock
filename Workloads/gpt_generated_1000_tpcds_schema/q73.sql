WITH base AS (
    SELECT
        d_date.d_date AS sales_date,
        sm.sm_ship_mode_id AS ship_mode_id,
        COALESCE(SUM(ss.ss_net_paid), 0) AS store_net_paid,
        COALESCE(SUM(cs.cs_net_paid), 0) AS catalog_net_paid,
        COALESCE(SUM(cr.cr_net_loss), 0) AS return_net_loss
    FROM
        store_sales ss
        RIGHT JOIN date_dim d_date
            ON ss.ss_sold_date_sk = d_date.d_date_sk
        LEFT JOIN time_dim td_ss
            ON ss.ss_sold_time_sk = td_ss.t_time_sk
        LEFT JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d_date.d_date_sk
        LEFT JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d_date.d_year = 2001
        AND d_date.d_fy_week_seq BETWEEN 10 AND 20
        AND td_ss.t_am_pm = 'PM'
        AND sm.sm_type = 'AIR'
        AND ss.ss_net_paid > 500
    GROUP BY
        d_date.d_date,
        sm.sm_ship_mode_id
)
SELECT
    ship_mode_id,
    AVG(total_net_revenue) AS avg_total_net_revenue,
    SUM(total_store_net) AS sum_store_net,
    SUM(total_catalog_net) AS sum_catalog_net,
    SUM(total_return_loss) AS sum_return_loss
FROM (
    SELECT
        ship_mode_id,
        (store_net_paid + catalog_net_paid - return_net_loss) AS total_net_revenue,
        store_net_paid AS total_store_net,
        catalog_net_paid AS total_catalog_net,
        return_net_loss AS total_return_loss
    FROM base
) agg
GROUP BY ship_mode_id
HAVING AVG(total_net_revenue) > 1000
ORDER BY avg_total_net_revenue DESC
LIMIT 100
