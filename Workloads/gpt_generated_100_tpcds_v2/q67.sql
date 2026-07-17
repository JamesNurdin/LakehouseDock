WITH store_yearly_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS yearly_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
)
SELECT
    s_year.s_store_name,
    AVG(s_year.yearly_net_profit) AS avg_yearly_net_profit,
    COUNT(*) AS years_count
FROM store_yearly_profit s_year
GROUP BY s_year.s_store_name
HAVING AVG(s_year.yearly_net_profit) > 50000
ORDER BY avg_yearly_net_profit DESC
LIMIT 10
