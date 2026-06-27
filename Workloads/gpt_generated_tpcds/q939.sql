WITH sales_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, sm.sm_type
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_moy,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, sm.sm_type
)
SELECT
    s.d_year,
    s.d_moy,
    s.sm_type,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_loss,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales_minus_returns,
    s.total_profit - COALESCE(r.total_loss, 0) AS net_profit_minus_loss
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.sm_type = r.sm_type
ORDER BY s.d_year, s.d_moy, s.sm_type
