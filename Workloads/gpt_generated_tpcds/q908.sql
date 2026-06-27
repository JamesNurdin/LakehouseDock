WITH sales_union AS (
    SELECT
        td.t_hour,
        sm.sm_ship_mode_id,
        cd.cd_gender,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    UNION ALL
    SELECT
        td.t_hour,
        sm.sm_ship_mode_id,
        cd.cd_gender,
        ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
),

sales_agg AS (
    SELECT
        t_hour,
        sm_ship_mode_id,
        cd_gender,
        SUM(net_paid_inc_tax) AS total_sales_amount,
        SUM(net_profit) AS total_sales_profit
    FROM sales_union
    GROUP BY t_hour, sm_ship_mode_id, cd_gender
),

returns_agg AS (
    SELECT
        td.t_hour,
        sm.sm_ship_mode_id,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY td.t_hour, sm.sm_ship_mode_id, cd.cd_gender
)
SELECT
    s.t_hour,
    s.sm_ship_mode_id,
    s.cd_gender,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_minus_returns,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.t_hour = r.t_hour
    AND s.sm_ship_mode_id = r.sm_ship_mode_id
    AND s.cd_gender = r.cd_gender
ORDER BY s.t_hour, s.sm_ship_mode_id, s.cd_gender
