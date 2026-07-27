WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_code,
        t.t_hour,
        cd.cd_credit_rating,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_quantity) AS total_qty,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
        AND cd.cd_credit_rating = 'Good'
        AND cd.cd_dep_college_count >= 1
        AND t.t_hour BETWEEN 9 AND 17
        AND ws.ws_wholesale_cost > 10
        AND ws.ws_net_profit > 0
    GROUP BY sm.sm_ship_mode_id, sm.sm_code, t.t_hour, cd.cd_credit_rating
)
SELECT
    sm_ship_mode_id,
    sm_code,
    t_hour,
    cd_credit_rating,
    order_cnt,
    total_qty,
    total_profit,
    avg_wholesale_cost,
    SUM(total_profit) OVER (PARTITION BY sm_ship_mode_id ORDER BY t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_hour,
    RANK() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY sm_ship_mode_id, t_hour
LIMIT 100
