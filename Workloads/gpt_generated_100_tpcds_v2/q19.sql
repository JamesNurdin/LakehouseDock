WITH store_year_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_year_net_profit
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        d.d_date >= DATE '1998-01-01'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year
)
SELECT
    d_year,
    AVG(store_year_net_profit) AS avg_store_year_profit
FROM
    store_year_profit
GROUP BY
    d_year
HAVING
    AVG(store_year_net_profit) > 1000000
ORDER BY
    d_year
