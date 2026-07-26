WITH profit_by_site_quarter AS (
    SELECT
        wsit.web_name,
        dd.d_quarter_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY wsit.web_name, dd.d_quarter_name
),
ranked AS (
    SELECT
        pb.web_name,
        pb.d_quarter_name,
        pb.total_net_profit,
        DENSE_RANK() OVER (PARTITION BY pb.d_quarter_name ORDER BY pb.total_net_profit DESC) AS profit_rank
    FROM profit_by_site_quarter pb
)
SELECT
    r.web_name,
    r.d_quarter_name,
    r.total_net_profit,
    r.profit_rank
FROM ranked r
WHERE r.profit_rank <= 10
ORDER BY r.d_quarter_name, r.profit_rank
