WITH combined AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        sm.sm_type AS ship_mode,
        cs.cs_net_profit AS profit,
        0.0 AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        sm.sm_type AS ship_mode,
        ws.ws_net_profit AS profit,
        0.0 AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        sm.sm_type AS ship_mode,
        0.0 AS profit,
        cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2020-01-01' AND d.d_date < DATE '2021-01-01'
)
SELECT
    d_year,
    month_seq,
    i_category,
    ship_mode,
    SUM(profit) - SUM(loss) AS net_profit
FROM combined
GROUP BY d_year, month_seq, i_category, ship_mode
ORDER BY d_year, month_seq, net_profit DESC
