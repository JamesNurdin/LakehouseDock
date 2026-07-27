WITH store_returns_agg AS (
    SELECT
        d.d_year AS year,
        'store_return' AS metric_type,
        SUM(sr.sr_net_loss) AS amount
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_net_loss > 100
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        'web_sales' AS metric_type,
        SUM(ws.ws_net_profit) AS amount
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_list_price > 100
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
)
SELECT year, metric_type, amount FROM store_returns_agg
UNION ALL
SELECT year, metric_type, amount FROM web_sales_agg
ORDER BY year, metric_type
LIMIT 100
