WITH web_sales_agg AS (
    SELECT d.d_date,
           SUM(ws.ws_ext_sales_price) AS total_amount,
           'web_sales' AS source
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'Y'
      AND d.d_year = 2020
    GROUP BY d.d_date
),
store_returns_agg AS (
    SELECT d.d_date,
           SUM(sr.sr_return_amt) AS total_amount,
           'store_returns' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY d.d_date
)
SELECT d_date,
       total_amount,
       source
FROM web_sales_agg
UNION ALL
SELECT d_date,
       total_amount,
       source
FROM store_returns_agg
ORDER BY d_date, source
LIMIT 100
