WITH sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, sm.sm_ship_mode_id
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        sm.sm_ship_mode_id,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, sm.sm_ship_mode_id
)
SELECT
    s.d_year,
    s.d_moy AS month,
    s.sm_ship_mode_id AS ship_mode,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    CASE
        WHEN s.total_net_profit = 0 THEN 0
        ELSE COALESCE(r.total_net_loss, 0) / s.total_net_profit
    END AS return_loss_rate
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.sm_ship_mode_id = r.sm_ship_mode_id
ORDER BY s.d_year, s.d_moy, s.sm_ship_mode_id
