WITH store_yearly_profit AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_id,
        d.d_year
)
SELECT
    d_year,
    AVG(total_net_profit) AS avg_store_profit,
    COUNT(*) AS store_count
FROM
    store_yearly_profit
GROUP BY
    d_year
HAVING
    AVG(total_net_profit) > 1000000
ORDER BY
    d_year
