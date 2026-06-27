WITH sales_returns AS (
    SELECT
        bill_addr.ca_state AS billing_state,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
    FROM web_sales ws
    JOIN customer_address bill_addr
        ON ws.ws_bill_addr_sk = bill_addr.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    GROUP BY bill_addr.ca_state, ws.ws_item_sk
)
SELECT
    billing_state,
    ws_item_sk,
    total_quantity_sold,
    total_sales_amount,
    total_sales_profit,
    total_quantity_returned,
    total_return_amount,
    total_return_loss,
    (total_quantity_returned / NULLIF(total_quantity_sold, 0)) * 100 AS return_rate_percent,
    (total_sales_profit - total_return_loss) AS net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY billing_state ORDER BY total_sales_amount DESC) AS rank_by_sales
FROM sales_returns
WHERE (total_quantity_returned / NULLIF(total_quantity_sold, 0)) * 100 > 5
ORDER BY billing_state, rank_by_sales
