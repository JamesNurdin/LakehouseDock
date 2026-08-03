WITH
    catalog_high_dates AS (
        SELECT d.d_date_sk
        FROM date_dim d
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_net_profit > 1000
        GROUP BY d.d_date_sk
    ),
    web_high_dates AS (
        SELECT d.d_date_sk
        FROM date_dim d
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE ws.ws_net_profit > 1000
        GROUP BY d.d_date_sk
    ),
    high_profit_dates AS (
        SELECT d_date_sk FROM catalog_high_dates
        INTERSECT
        SELECT d_date_sk FROM web_high_dates
    ),
    store_sales AS (
        SELECT
            s.s_store_name,
            d.d_year,
            d.d_month_seq,
            SUM(cs.cs_net_profit) AS catalog_profit,
            SUM(ws.ws_net_profit) AS web_profit
        FROM store s
        JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_date_sk IN (SELECT d_date_sk FROM high_profit_dates)
          AND s.s_country = 'United States'
        GROUP BY CUBE(s.s_store_name, d.d_year, d.d_month_seq)
    )
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    COALESCE(catalog_profit, 0) AS catalog_profit,
    COALESCE(web_profit, 0) AS web_profit,
    (SELECT AVG(cs_net_profit) FROM catalog_sales) AS avg_catalog_profit
FROM store_sales
WHERE catalog_profit IS NOT NULL OR web_profit IS NOT NULL
ORDER BY catalog_profit DESC NULLS LAST
LIMIT 100
