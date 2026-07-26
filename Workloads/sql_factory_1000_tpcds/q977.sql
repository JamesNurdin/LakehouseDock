WITH store_sales AS (
    SELECT
        s.s_store_name,
        d.d_date,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_ship_date_sk = d.d_date_sk
    GROUP BY s.s_store_name, d.d_date
),
ranked AS (
    SELECT
        ss.s_store_name,
        ss.d_date AS closed_date,
        ss.total_net_profit,
        CASE
            WHEN ss.total_net_profit > 100000 THEN 'HIGH'
            WHEN ss.total_net_profit > 50000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_tier,
        RANK() OVER (PARTITION BY CASE
                WHEN ss.total_net_profit > 100000 THEN 'HIGH'
                WHEN ss.total_net_profit > 50000 THEN 'MEDIUM'
                ELSE 'LOW'
            END ORDER BY ss.total_net_profit DESC) AS tier_rank,
        LAG(ss.total_net_profit) OVER (ORDER BY ss.d_date) AS prev_day_profit,
        CASE
            WHEN LAG(ss.total_net_profit) OVER (ORDER BY ss.d_date) = 0 THEN 0
            ELSE (ss.total_net_profit - LAG(ss.total_net_profit) OVER (ORDER BY ss.d_date)) /
                 LAG(ss.total_net_profit) OVER (ORDER BY ss.d_date)
        END AS profit_change_pct
    FROM store_sales ss
)
SELECT
    r.s_store_name,
    r.closed_date,
    r.total_net_profit,
    r.profit_tier,
    r.tier_rank,
    r.prev_day_profit,
    r.profit_change_pct
FROM ranked r
WHERE r.tier_rank <= 3
ORDER BY r.profit_tier, r.tier_rank
