WITH base AS (
    SELECT
        s.s_store_name,
        r.r_reason_desc,
        ss.ss_quantity,
        ss.ss_net_profit,
        wr.wr_return_amt,
        wr.wr_return_ship_cost,
        t.t_shift
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE s.s_manager = 'Jerry Brooks'
        AND s.s_hours = '8AM-12AM'
        AND t.t_shift = 'second'
        AND r.r_reason_desc LIKE '%defect%'
        AND wr.wr_return_ship_cost > 100
),
aggregated AS (
    SELECT
        s_store_name,
        r_reason_desc,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(wr_return_amt) AS total_return_amount,
        AVG(ss_quantity) AS avg_quantity,
        SUM(wr_return_ship_cost) AS total_ship_cost
    FROM base
    GROUP BY s_store_name, r_reason_desc
)
SELECT
    s_store_name,
    r_reason_desc,
    total_net_profit,
    total_return_amount,
    total_ship_cost,
    avg_quantity,
    (total_net_profit / NULLIF(total_return_amount, 0)) AS profit_return_ratio
FROM aggregated
WHERE total_ship_cost > 200
    AND avg_quantity >= 1
    AND (total_net_profit / NULLIF(total_return_amount, 0)) > 0.5
ORDER BY profit_return_ratio DESC
LIMIT 100
