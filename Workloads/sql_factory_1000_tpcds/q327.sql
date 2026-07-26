WITH daily_sales AS (
    SELECT
        d.d_date,
        d.d_day_name,
        d.d_weekend,
        SUM(ss.ss_ext_sales_price) AS daily_sales_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_day_name, d.d_weekend
),
daily_returns AS (
    SELECT
        d.d_date,
        SUM(sr.sr_net_loss) AS daily_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
 daily_net AS (
    SELECT
        s.d_date,
        s.d_day_name,
        s.d_weekend,
        s.daily_sales_amount,
        COALESCE(r.daily_return_loss, 0) AS daily_return_loss,
        (s.daily_sales_amount - COALESCE(r.daily_return_loss, 0)) AS net_revenue
    FROM daily_sales s
    LEFT JOIN daily_returns r ON s.d_date = r.d_date
)
SELECT
    d_date,
    d_day_name,
    CASE WHEN d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    daily_sales_amount,
    daily_return_loss,
    net_revenue,
    LAG(net_revenue) OVER (ORDER BY d_date) AS previous_day_revenue,
    CASE
        WHEN LAG(net_revenue) OVER (ORDER BY d_date) IS NULL THEN NULL
        ELSE (net_revenue - LAG(net_revenue) OVER (ORDER BY d_date)) / LAG(net_revenue) OVER (ORDER BY d_date)
    END AS revenue_growth_ratio
FROM daily_net
WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
ORDER BY d_date
