WITH ws_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND w.w_street_type IN ('Rd', 'Avenue')
      AND ws.ws_list_price > 50
      AND ws.ws_ext_tax < 500
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
)
SELECT
    w_agg.w_warehouse_id,
    w_agg.w_warehouse_name,
    w_agg.w_city,
    w_agg.w_state,
    w_agg.total_net_profit,
    w_agg.total_sales,
    w_agg.avg_discount,
    w_agg.order_count,
    RANK() OVER (ORDER BY w_agg.total_net_profit DESC) AS profit_rank,
    CASE WHEN w_agg.total_net_profit > 100000 THEN 'High' ELSE 'Medium' END AS profit_category,
    SUM(w_agg.total_net_profit) OVER (
        ORDER BY w_agg.total_net_profit DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS profit_running_sum_3
FROM ws_agg w_agg
ORDER BY profit_rank
LIMIT 100
