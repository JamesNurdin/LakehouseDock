WITH cs AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
),
cr AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sm.sm_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
),
ws AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sm.sm_type,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(ws.ws_net_profit) AS total_ws_net_profit,
        SUM(ws.ws_quantity) AS total_ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, sm.sm_type
)
SELECT
    cs.d_year,
    cs.d_month_seq,
    cs.i_category,
    cs.sm_type,
    cs.total_net_paid,
    cs.total_net_profit,
    cr.total_net_loss,
    ws.total_ws_net_paid,
    ws.total_ws_net_profit,
    (cs.total_net_paid - COALESCE(cr.total_net_loss, 0) + ws.total_ws_net_paid) AS net_revenue
FROM cs
LEFT JOIN cr
    ON cs.d_year = cr.d_year
   AND cs.d_month_seq = cr.d_month_seq
   AND cs.i_category = cr.i_category
   AND cs.sm_type = cr.sm_type
LEFT JOIN ws
    ON cs.d_year = ws.d_year
   AND cs.d_month_seq = ws.d_month_seq
   AND cs.i_category = ws.i_category
   AND cs.sm_type = ws.sm_type
ORDER BY cs.d_year, cs.d_month_seq, cs.i_category, cs.sm_type
