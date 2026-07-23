WITH agg AS (
    SELECT
        td_ret.t_shift AS return_shift,
        td_ret.t_hour AS return_hour,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_sales ws
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td_ret
        ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN time_dim td_sold
        ON ws.ws_sold_time_sk = td_sold.t_time_sk
    WHERE
        TRIM(td_ret.t_shift) = 'first'
        AND ws.ws_ext_list_price > 500
        AND wr.wr_return_quantity > 1
        AND TRIM(td_sold.t_shift) = 'second'
        AND td_ret.t_second < 10
    GROUP BY
        td_ret.t_shift,
        td_ret.t_hour,
        ws.ws_item_sk
)
SELECT
    return_shift,
    return_hour,
    ws_item_sk,
    total_sales,
    total_return_amount,
    total_return_loss,
    CASE 
        WHEN total_return_amount > 0 THEN total_return_loss / total_return_amount
        ELSE 0
    END AS loss_rate,
    RANK() OVER (PARTITION BY return_shift ORDER BY total_return_loss DESC) AS loss_rank,
    ROW_NUMBER() OVER (PARTITION BY return_shift ORDER BY total_return_amount DESC) AS amount_rank
FROM agg
ORDER BY return_shift, loss_rank
