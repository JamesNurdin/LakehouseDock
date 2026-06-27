WITH sales AS (
    SELECT
        d.d_date AS sales_date,
        i.i_category AS category,
        sm.sm_ship_mode_id AS ship_mode,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_date, i.i_category, sm.sm_ship_mode_id
),
returns AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        sm.sm_ship_mode_id AS ship_mode,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_date, i.i_category, sm.sm_ship_mode_id
)
SELECT
    COALESCE(s.sales_date, r.return_date) AS date,
    COALESCE(s.category, r.category) AS category,
    COALESCE(s.ship_mode, r.ship_mode) AS ship_mode,
    COALESCE(s.total_net_paid, 0) AS total_net_paid,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    COALESCE(s.sales_cnt, 0) AS sales_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns
FROM sales s
FULL OUTER JOIN returns r
    ON s.sales_date = r.return_date
    AND s.category = r.category
    AND s.ship_mode = r.ship_mode
ORDER BY date, category, ship_mode
