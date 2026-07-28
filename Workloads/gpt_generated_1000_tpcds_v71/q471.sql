WITH
    ss AS (
        SELECT
            ss_ext_sales_price,
            ss_promo_sk,
            ss_sold_time_sk,
            ss_addr_sk
        FROM store_sales ss
    ),
    ws AS (
        SELECT
            ws_ext_sales_price,
            ws_promo_sk,
            ws_sold_time_sk,
            ws_bill_addr_sk,
            ws_ship_addr_sk,
            ws_item_sk,
            ws_order_number
        FROM web_sales ws
    ),
    wr AS (
        SELECT
            wr_return_amt,
            wr_returned_time_sk,
            wr_refunded_addr_sk,
            wr_returning_addr_sk,
            wr_item_sk,
            wr_order_number
        FROM web_returns wr
    )
SELECT
    p.p_promo_name AS promo_name,
    td_ws.t_hour AS hour_of_day,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(wr.wr_return_amt) AS returns_total,
    (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt)) AS net_revenue,
    CASE
        WHEN (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt)) > 10000 THEN 'High'
        ELSE 'Low'
    END AS revenue_category
FROM ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim td_ss
    ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN ws
    ON ss.ss_promo_sk = ws.ws_promo_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer_address ca_ws_bill
    ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
    ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
GROUP BY ROLLUP(p.p_promo_name, td_ws.t_hour)
HAVING (SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt)) > 5000
ORDER BY net_revenue DESC
LIMIT 100
