WITH sales_by_year AS (
    SELECT
        d.d_year AS year,
        CAST('catalog' AS varchar) AS channel,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 1000000 THEN 'high' ELSE 'low' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
    HAVING SUM(cs.cs_net_profit) <> 0

    UNION ALL

    SELECT
        d.d_year AS year,
        CAST('web' AS varchar) AS channel,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 1000000 THEN 'high' ELSE 'low' END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
    HAVING SUM(ws.ws_net_profit) <> 0
)
SELECT
    s.year,
    s.channel,
    s.total_profit,
    s.profit_category,
    (SELECT AVG(total_profit) FROM sales_by_year sb WHERE sb.year = s.year) AS avg_profit_same_year
FROM sales_by_year s
WHERE s.total_profit > (SELECT AVG(total_profit) FROM sales_by_year)
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = s.year
          AND cr.cr_net_loss > 0
    )
ORDER BY s.year DESC, s.total_profit DESC
LIMIT 100
