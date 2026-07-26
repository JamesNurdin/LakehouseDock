WITH sales_returns AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        cr.cr_net_loss,
        td.t_hour,
        td.t_shift,
        CASE
            WHEN ws.ws_net_profit - cr.cr_net_loss > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS profit_status
    FROM web_sales ws
    JOIN catalog_returns cr
        ON ws.ws_order_number = cr.cr_order_number
        AND ws.ws_item_sk = cr.cr_item_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
)
SELECT
    ws_item_sk,
    t_hour,
    t_shift,
    SUM(ws_net_profit) AS total_sales_profit,
    SUM(cr_net_loss) AS total_return_loss,
    SUM(ws_net_profit - cr_net_loss) AS net_balance,
    COUNT(*) AS txn_count,
    DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit - cr_net_loss) DESC) AS profit_rank,
    CASE
        WHEN SUM(ws_net_profit - cr_net_loss) > 0 THEN 'Overall Profit'
        ELSE 'Overall Loss'
    END AS overall_status
FROM sales_returns
GROUP BY ws_item_sk, t_hour, t_shift
HAVING SUM(ws_net_profit - cr_net_loss) > 0
ORDER BY profit_rank
