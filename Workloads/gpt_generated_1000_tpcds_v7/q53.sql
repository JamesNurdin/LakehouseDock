/*
Goal: Compare net paid revenue from physical stores versus web sales for the year 2001, showing the sales channel, date, store division (if applicable), net paid amount and net profit. The results from both channels are combined with UNION ALL, ordered by revenue, and limited to the top 100 rows.
*/
WITH store_data AS (
    SELECT
        'store' AS channel,
        d.d_date AS sales_date,
        s.s_division_name AS division,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_tax_percentage > 0.05
),
web_data AS (
    SELECT
        'web' AS channel,
        d.d_date AS sales_date,
        CAST(NULL AS varchar) AS division,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_sales_price > 20
)
SELECT channel,
       sales_date,
       division,
       net_paid,
       net_profit
FROM store_data
UNION ALL
SELECT channel,
       sales_date,
       division,
       net_paid,
       net_profit
FROM web_data
ORDER BY net_paid DESC
LIMIT 100
