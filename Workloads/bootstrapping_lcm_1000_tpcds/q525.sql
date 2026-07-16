WITH agg_returns AS (
    SELECT 
        d.d_quarter_name AS quarter,
        s.s_division_name AS division,
        ws.web_market_manager AS market_manager,
        ws.web_tax_percentage AS tax_percentage,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(CASE WHEN t.t_hour < 12 THEN 1 ELSE 0 END) AS morning_returns,
        SUM(CASE WHEN t.t_hour >= 12 THEN 1 ELSE 0 END) AS afternoon_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk AND ws.web_close_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ws.web_country = 'United States'
    GROUP BY d.d_quarter_name, s.s_division_name, ws.web_market_manager, ws.web_tax_percentage
)
SELECT
    quarter,
    division,
    market_manager,
    tax_percentage,
    num_returns,
    total_net_loss,
    avg_return_amount,
    total_fee,
    total_quantity,
    morning_returns,
    afternoon_returns,
    ROUND(morning_returns * 100.0 / NULLIF(num_returns, 0), 2) AS pct_morning_returns,
    RANK() OVER (PARTITION BY quarter ORDER BY total_net_loss DESC) AS division_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100
