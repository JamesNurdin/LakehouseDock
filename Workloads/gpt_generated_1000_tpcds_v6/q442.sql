WITH base AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(CASE WHEN sm.sm_type = 'AIR' THEN ws.ws_ext_ship_cost ELSE 0 END) AS air_ship_cost,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
        LEFT JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_weekend = 'N'
        AND d.d_year = 2002
        AND t.t_hour BETWEEN 8 AND 17
        AND sm.sm_type IN ('AIR', 'RAIL')
        AND ws.ws_ext_ship_cost > 100
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_month_seq
)
SELECT
    b.s_store_id,
    b.d_year,
    b.d_month_seq,
    b.total_web_profit,
    b.total_return_loss,
    (b.total_web_profit - b.total_return_loss) AS net_total,
    CASE WHEN b.total_return_loss > 0 THEN 'LOSS' ELSE 'NO LOSS' END AS loss_flag,
    ROW_NUMBER() OVER (PARTITION BY b.d_year ORDER BY (b.total_web_profit - b.total_return_loss) DESC) AS profit_rank,
    b.distinct_orders,
    b.air_ship_cost,
    b.total_inventory_on_hand
FROM
    base b
WHERE
    (b.total_web_profit - b.total_return_loss) > 0
ORDER BY
    b.d_year,
    profit_rank
LIMIT 100
