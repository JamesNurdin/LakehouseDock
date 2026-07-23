WITH store_monthly AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        'Store' AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        'Web' AS channel,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT d_year, d_month_seq, channel, total_profit, total_sales
FROM store_monthly
UNION ALL
SELECT d_year, d_month_seq, channel, total_profit, total_sales
FROM web_monthly
ORDER BY d_year, d_month_seq, channel
LIMIT 100
