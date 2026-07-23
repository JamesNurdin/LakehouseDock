WITH avg_category_profit AS (
    SELECT i.i_category AS category,
           AVG(ss.ss_net_profit) AS avg_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    d.d_year AS year,
    i.i_category AS category,
    'sales' AS metric_type,
    SUM(ss.ss_net_profit) AS metric_amount,
    (
        SELECT acp.avg_net_profit
        FROM avg_category_profit acp
        WHERE acp.category = i.i_category
    ) AS avg_category_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_date >= DATE '2000-01-01'
  AND d.d_date < DATE '2003-01-01'
GROUP BY d.d_year, i.i_category
HAVING SUM(ss.ss_net_profit) > 5000

UNION ALL

SELECT
    d.d_year AS year,
    i.i_category AS category,
    'returns' AS metric_type,
    SUM(sr.sr_net_loss) AS metric_amount,
    (
        SELECT acp.avg_net_profit
        FROM avg_category_profit acp
        WHERE acp.category = i.i_category
    ) AS avg_category_profit
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
WHERE d.d_date >= DATE '2000-01-01'
  AND d.d_date < DATE '2003-01-01'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE ss2.ss_item_sk = sr.sr_item_sk
          AND d2.d_date >= DATE '2000-01-01'
          AND d2.d_date < DATE '2003-01-01'
          AND ss2.ss_net_profit > 0
    )
GROUP BY d.d_year, i.i_category
HAVING SUM(sr.sr_net_loss) > 1000

ORDER BY year, category, metric_type
LIMIT 100
