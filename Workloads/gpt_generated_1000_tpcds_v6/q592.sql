WITH web_agg AS (
    SELECT d.d_year AS year,
           'Web' AS source,
           SUM(ws.ws_net_paid) AS total_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'N'
    GROUP BY d.d_year, 'Web'
),
store_agg AS (
    SELECT d.d_year AS year,
           'Store' AS source,
           SUM(sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = sr.sr_reason_sk
          AND r.r_reason_desc = 'Damaged Goods'
    )
    GROUP BY d.d_year, 'Store'
)
SELECT year, source, total_amount
FROM web_agg
UNION ALL
SELECT year, source, total_amount
FROM store_agg
ORDER BY year DESC, total_amount DESC
LIMIT 100
