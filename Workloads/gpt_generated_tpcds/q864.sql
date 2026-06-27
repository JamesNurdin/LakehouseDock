WITH store AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
catalog AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
web AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
combined AS (
    SELECT COALESCE(s.year, c.year, w.year)               AS year,
           COALESCE(s.month_seq, c.month_seq, w.month_seq) AS month_seq,
           COALESCE(s.store_net_profit, 0)               AS store_net_profit,
           COALESCE(c.catalog_net_profit, 0)             AS catalog_net_profit,
           COALESCE(w.web_net_profit, 0)                 AS web_net_profit,
           COALESCE(s.store_net_profit, 0) +
           COALESCE(c.catalog_net_profit, 0) +
           COALESCE(w.web_net_profit, 0)                 AS total_net_profit
    FROM store   s
    FULL OUTER JOIN catalog c ON s.year = c.year AND s.month_seq = c.month_seq
    FULL OUTER JOIN web    w ON COALESCE(s.year, c.year) = w.year
                                 AND COALESCE(s.month_seq, c.month_seq) = w.month_seq
)
SELECT year,
       month_seq,
       store_net_profit,
       catalog_net_profit,
       web_net_profit,
       total_net_profit,
       CASE WHEN total_net_profit = 0 THEN 0
            ELSE web_net_profit / total_net_profit
       END AS web_profit_ratio
FROM combined
ORDER BY year, month_seq
