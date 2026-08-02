WITH
sales_data AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_net_profit AS sales_net_profit,
        i.i_category,
        i.i_brand,
        cd.cd_credit_rating,
        td.t_hour
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
),
web_sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_paid_inc_tax,
        i_ws.i_category AS ws_category,
        cd_bill.cd_credit_rating AS bill_credit_rating,
        cd_ship.cd_credit_rating AS ship_credit_rating,
        td_ws.t_hour AS ws_hour
    FROM web_sales ws
    JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
),
returns_data AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        i_wr.i_category AS return_category,
        cd_refunded.cd_credit_rating AS refunded_credit_rating,
        cd_returning.cd_credit_rating AS returning_credit_rating,
        td_wr.t_hour AS return_hour
    FROM web_returns wr
    JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
),
orders_wo_returns AS (
    SELECT ws_order_number FROM web_sales_data
    EXCEPT
    SELECT wr_order_number FROM returns_data
)
SELECT
    cd_demo.cd_credit_rating,
    i_cat.i_category,
    SUM(s.sales_net_profit) AS total_store_profit,
    SUM(w.ws_net_paid_inc_tax) AS total_web_sales,
    SUM(CASE WHEN r.wr_return_quantity IS NULL THEN 0 ELSE r.wr_return_quantity END) AS total_return_quantity,
    CASE WHEN SUM(s.sales_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM sales_data s
JOIN web_sales_data w
    ON s.ss_item_sk = w.ws_item_sk
LEFT JOIN returns_data r
    ON w.ws_order_number = r.wr_order_number
JOIN customer_demographics cd_demo
    ON s.ss_cdemo_sk = cd_demo.cd_demo_sk
JOIN item i_cat
    ON s.ss_item_sk = i_cat.i_item_sk
WHERE w.ws_order_number IN (SELECT ws_order_number FROM orders_wo_returns)
GROUP BY cd_demo.cd_credit_rating, i_cat.i_category
ORDER BY total_store_profit DESC
LIMIT 100
