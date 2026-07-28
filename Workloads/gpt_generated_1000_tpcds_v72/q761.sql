WITH sales_agg AS (
    SELECT
        sm_cs.sm_ship_mode_id,
        i_cs.i_category,
        SUM(cs.cs_net_profit) AS sum_cs_profit,
        SUM(ss.ss_net_profit) AS sum_ss_profit,
        SUM(ws.ws_net_profit) AS sum_ws_profit,
        SUM(wr.wr_net_loss) AS sum_wr_loss
    FROM catalog_sales cs
    JOIN ship_mode sm_cs
        ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN item i_cs
        ON cs.cs_item_sk = i_cs.i_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i_cs.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i_cs.i_item_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i_ss
        ON ss.ss_item_sk = i_ss.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i_cs.i_item_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN item i_wr
        ON wr.wr_item_sk = i_wr.i_item_sk
    GROUP BY
        sm_cs.sm_ship_mode_id,
        i_cs.i_category
)
SELECT
    sm_ship_mode_id,
    i_category,
    sum_cs_profit,
    sum_ss_profit,
    sum_ws_profit,
    sum_wr_loss,
    (sum_cs_profit + sum_ss_profit + sum_ws_profit - sum_wr_loss) AS total_profit,
    CASE WHEN (sum_cs_profit + sum_ss_profit + sum_ws_profit - sum_wr_loss) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY (sum_cs_profit + sum_ss_profit + sum_ws_profit - sum_wr_loss) DESC) AS rn
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
