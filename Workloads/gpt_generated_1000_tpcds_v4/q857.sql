WITH ss AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_sold_time_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
),
ws AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_sold_time_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_web_page_sk
    FROM web_sales ws
),
wr AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_order_number,
        wr.wr_web_page_sk
    FROM web_returns wr
)
SELECT
    i_ss.i_category,
    c.c_birth_month,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(ss.ss_net_profit + ws.ws_net_profit - wr.wr_net_loss) AS net_contribution,
    CASE
        WHEN SUM(ss.ss_net_profit + ws.ws_net_profit - wr.wr_net_loss) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_level,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM ss
JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk

JOIN ws ON ss.ss_item_sk = ws.ws_item_sk
JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk

JOIN wr ON ws.ws_order_number = wr.wr_order_number
JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer c_return ON wr.wr_returning_customer_sk = c_return.c_customer_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk

JOIN web_page wp_cust ON wp_cust.wp_customer_sk = c.c_customer_sk
WHERE i_ss.i_category = 'Electronics'
  AND c.c_birth_month IN (1, 5, 10)
GROUP BY i_ss.i_category, c.c_birth_month
HAVING SUM(ss.ss_net_profit + ws.ws_net_profit - wr.wr_net_loss) > 5000
ORDER BY net_contribution DESC
LIMIT 100
