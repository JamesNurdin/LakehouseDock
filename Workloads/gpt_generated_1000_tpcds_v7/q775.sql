WITH store_sales_agg AS (
    SELECT d.d_year AS year,
           'store' AS channel,
           SUM(ss.ss_net_paid) AS total_amount
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_sales_price > 10
    GROUP BY d.d_year
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           'web' AS channel,
           SUM(ws.ws_net_paid) AS total_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_sales_price > 10
    GROUP BY d.d_year
),
store_returns_agg AS (
    SELECT d.d_year AS year,
           'store_return' AS channel,
           SUM(sr.sr_return_amt) AS total_amount
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY d.d_year
)
SELECT year,
       channel,
       total_amount
FROM (
    SELECT year, channel, total_amount FROM store_sales_agg
    UNION ALL
    SELECT year, channel, total_amount FROM web_sales_agg
    UNION ALL
    SELECT year, channel, total_amount FROM store_returns_agg
) AS combined
ORDER BY year DESC,
         total_amount DESC
LIMIT 100
