WITH sales_agg AS (
    SELECT
        wh.w_warehouse_sk,
        wh.w_warehouse_name,
        td.t_hour,
        td.t_time_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        MAX(ws.ws_wholesale_cost) AS max_wholesale_cost,
        CASE WHEN SUM(ws.ws_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS quantity_category
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_web ON r_web.r_reason_sk = wr.wr_reason_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r_store ON r_store.r_reason_sk = sr.sr_reason_sk
    WHERE
        td.t_time_sk IN (9, 13)
        AND ws.ws_quantity > 2
        AND wh.w_warehouse_sq_ft > 20000
        AND wp.wp_type = 'C'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        wh.w_warehouse_sk,
        wh.w_warehouse_name,
        td.t_hour,
        td.t_time_sk
)
SELECT
    sa.w_warehouse_name,
    sa.t_hour,
    sa.total_net_profit,
    sa.total_quantity,
    sa.quantity_category,
    CASE WHEN sa.total_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    sa.total_web_return_loss,
    sa.total_store_return_loss,
    sa.max_wholesale_cost,
    (SELECT MAX(ws3.ws_wholesale_cost) FROM web_sales ws3) AS overall_max_wholesale_cost,
    SUM(sa.total_net_profit) OVER (PARTITION BY sa.w_warehouse_name ORDER BY sa.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit,
    (
        SELECT COUNT(*)
        FROM inventory inv_corr
        WHERE inv_corr.inv_warehouse_sk = sa.w_warehouse_sk
          AND inv_corr.inv_quantity_on_hand > sa.total_quantity
    ) AS high_inventory_count
FROM sales_agg sa
ORDER BY sa.total_net_profit DESC
