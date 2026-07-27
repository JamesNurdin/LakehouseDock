WITH daily_sales AS (
    SELECT
        d_sold.d_date,
        d_sold.d_day_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        CASE
            WHEN d_sold.d_current_quarter = 'Y' THEN 'CurrentQuarter'
            ELSE 'OtherQuarter'
        END AS quarter_flag
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE
        ws.ws_coupon_amt > 0
        AND ws.ws_quantity >= 1
        AND ws.ws_wholesale_cost BETWEEN 30 AND 80
        AND d_sold.d_year = 2001
        AND d_sold.d_month_seq BETWEEN 1200 AND 1210
        AND t.t_hour BETWEEN 9 AND 17
        AND d_sold.d_current_week = 'N'
        AND d_ship.d_current_quarter = 'N'
    GROUP BY
        d_sold.d_date,
        d_sold.d_day_name,
        CASE
            WHEN d_sold.d_current_quarter = 'Y' THEN 'CurrentQuarter'
            ELSE 'OtherQuarter'
        END
)
SELECT
    ds.d_day_name,
    ds.quarter_flag,
    AVG(ds.total_sales) AS avg_daily_sales,
    SUM(ds.total_profit) AS sum_profit,
    COUNT(*) AS days_count,
    CASE
        WHEN AVG(ds.total_sales) > (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_coupon_amt > 0
        ) THEN 'AboveAvg'
        ELSE 'BelowAvg'
    END AS sales_category
FROM daily_sales ds
WHERE ds.order_count > 10
GROUP BY
    ds.d_day_name,
    ds.quarter_flag
HAVING SUM(ds.total_profit) > 1000
ORDER BY avg_daily_sales DESC
LIMIT 100
