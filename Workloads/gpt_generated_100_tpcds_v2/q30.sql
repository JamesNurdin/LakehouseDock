WITH store_profit AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT
    sp.s_store_name,
    sp.total_net_profit,
    sp.transaction_count,
    avg_store_profit
FROM (
    SELECT
        sp.s_store_name,
        sp.total_net_profit,
        sp.transaction_count,
        (SELECT AVG(total_net_profit) FROM store_profit) AS avg_store_profit
    FROM store_profit sp
) sp
WHERE sp.total_net_profit > sp.avg_store_profit
ORDER BY sp.total_net_profit DESC
