WITH date_filter AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_date
    FROM   date_dim
    WHERE  d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
),
combined_sales AS (
    SELECT
        'store'   AS channel,
        df.d_year AS year,
        df.d_month_seq AS month,
        SUM(ss.ss_net_profit) AS net_profit
    FROM   store_sales ss
    JOIN   date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP  BY df.d_year, df.d_month_seq
    UNION ALL
    SELECT
        'catalog' AS channel,
        df.d_year AS year,
        df.d_month_seq AS month,
        SUM(cs.cs_net_profit) AS net_profit
    FROM   catalog_sales cs
    JOIN   date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP  BY df.d_year, df.d_month_seq
)
SELECT
    cs.channel,
    cs.year,
    cs.month,
    cs.net_profit,
    cs.net_profit - (
        SELECT AVG(month_net_profit)
        FROM (
            SELECT SUM(ss2.ss_net_profit) AS month_net_profit
            FROM   store_sales ss2
            JOIN   date_filter df2 ON ss2.ss_sold_date_sk = df2.d_date_sk
            GROUP  BY df2.d_year, df2.d_month_seq
            UNION ALL
            SELECT SUM(cs2.cs_net_profit) AS month_net_profit
            FROM   catalog_sales cs2
            JOIN   date_filter df2 ON cs2.cs_sold_date_sk = df2.d_date_sk
            GROUP  BY df2.d_year, df2.d_month_seq
        ) AS avg_sub
    ) AS profit_vs_avg,
    SUM(cs.net_profit) OVER (
        PARTITION BY cs.channel
        ORDER BY cs.year, cs.month
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_net_profit,
    ROW_NUMBER() OVER (
        PARTITION BY cs.channel
        ORDER BY cs.year, cs.month
    ) AS month_rank
FROM   combined_sales cs
WHERE  EXISTS (
    SELECT 1
    FROM   promotion p
    JOIN   date_filter dfp ON p.p_start_date_sk = dfp.d_date_sk
    WHERE  dfp.d_year = cs.year
      AND  dfp.d_month_seq = cs.month
)
ORDER BY cs.channel, cs.year, cs.month
LIMIT 100
