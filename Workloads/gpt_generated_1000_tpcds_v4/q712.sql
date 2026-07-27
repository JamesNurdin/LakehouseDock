WITH sr_agg AS (
        SELECT
            sr_returned_date_sk,
            SUM(sr_return_amt) AS total_return_amt,
            COUNT(*) AS cnt_returns
        FROM store_returns
        WHERE sr_fee > 10.00                     -- filter 1
          AND sr_reversed_charge < 500.00        -- filter 2
          AND sr_customer_sk IN (5920820, 54588, 5167006)  -- filter 3
        GROUP BY sr_returned_date_sk
    ),
    ws_agg AS (
        SELECT
            ws_sold_date_sk,
            SUM(ws_ext_sales_price) AS total_sales,
            SUM(ws_net_profit) AS total_profit,
            COUNT(*) AS cnt_sales
        FROM web_sales
        WHERE ws_quantity > 1                         -- filter 4
          AND ws_ship_cdemo_sk NOT IN (601676, 468964) -- filter 5
          AND ws_wholesale_cost > 5.00                 -- filter 6
        GROUP BY ws_sold_date_sk
    )
SELECT
    d.d_date,
    d.d_day_name,
    d.d_current_year,
    sr.total_return_amt,
    ws.total_sales,
    ws.total_profit,
    (ws.total_sales - sr.total_return_amt) AS net_revenue,
    RANK() OVER (ORDER BY (ws.total_sales - sr.total_return_amt) DESC) AS revenue_rank,
    CASE
        WHEN (ws.total_sales - sr.total_return_amt) > 10000 THEN 'High'
        WHEN (ws.total_sales - sr.total_return_amt) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM date_dim d
JOIN sr_agg sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN ws_agg ws ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001                                 -- filter 7
  AND d.d_month_seq BETWEEN 1200 AND 1220            -- filter 8
  AND d.d_holiday = 'N'                               -- filter 9
  AND d.d_weekend = 'N'                               -- filter 10
  AND d.d_day_name = 'Tuesday  '                     -- filter 11
ORDER BY revenue_rank
LIMIT 100
