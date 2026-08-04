WITH returns AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE regexp_like(d.d_day_name, '^Mon|Tue')
      AND d.d_holiday LIKE 'Y%'
    GROUP BY sr.sr_returned_date_sk
),
sales AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(d.d_quarter_name, 'Q[1-4]')
      AND d.d_current_month LIKE '2021%'
    GROUP BY ws.ws_sold_date_sk
),
common_dates AS (
    SELECT date_sk FROM returns
    INTERSECT
    SELECT date_sk FROM sales
),
final AS (
    SELECT
        d.d_date,
        d.d_day_name,
        CONCAT(d.d_day_name, '-', d.d_holiday) AS day_holiday_flag,
        r.total_return_amt,
        s.total_sales,
        r.cnt_returns,
        s.cnt_sales,
        (
            SELECT SUM(ws3.ws_net_profit)
            FROM web_sales ws3
            WHERE ws3.ws_sold_date_sk = d.d_date_sk
        ) AS profit_by_date,
        SUM(COALESCE(r.total_return_amt, 0)) OVER (
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_return_amt
    FROM date_dim d
    JOIN common_dates cd ON d.d_date_sk = cd.date_sk
    LEFT JOIN returns r ON r.date_sk = d.d_date_sk
    LEFT JOIN sales s ON s.date_sk = d.d_date_sk
    WHERE regexp_extract(d.d_day_name, '(Mon|Tue|Wed|Thu|Fri)', 1) IS NOT NULL
)
SELECT
    d_date,
    d_day_name,
    day_holiday_flag,
    total_return_amt,
    total_sales,
    cnt_returns,
    cnt_sales,
    profit_by_date,
    running_return_amt
FROM final
ORDER BY d_date DESC
LIMIT 100
