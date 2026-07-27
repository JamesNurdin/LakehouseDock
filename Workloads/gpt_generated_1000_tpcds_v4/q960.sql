WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sold_time_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk = 2450815
      AND ws_quantity > 2
      AND ws_item_sk IN (250293, 261050)
      AND ws_bill_hdemo_sk = 3376
    GROUP BY ws_item_sk, ws_order_number, ws_sold_time_sk
)
SELECT
    ca_ret_state.ca_state AS returning_state,
    t_cr.t_hour,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(ws_agg.total_sales) AS total_sales,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM catalog_returns cr
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_ret_state
    ON cr.cr_returning_addr_sk = ca_ret_state.ca_address_sk
JOIN ws_agg
    ON ws_agg.ws_sold_time_sk = t_cr.t_time_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws_agg.ws_item_sk
   AND wr.wr_order_number = ws_agg.ws_order_number
JOIN customer_address ca_wr_refund
    ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_return
    ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
WHERE t_cr.t_am_pm = 'PM'
  AND ca_ret_state.ca_state = 'CA'
  AND cr.cr_net_loss > 50
  AND wr.wr_return_quantity >= 1
  AND ca_wr_refund.ca_state = 'NY'
GROUP BY ca_ret_state.ca_state, t_cr.t_hour
ORDER BY total_sales DESC
LIMIT 100
