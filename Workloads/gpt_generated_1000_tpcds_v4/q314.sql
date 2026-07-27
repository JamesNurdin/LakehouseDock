WITH sales_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
    FROM web_sales ws
)
SELECT
    wh.w_warehouse_name,
    ws_site.web_name AS site_name,
    i_sold.i_category,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(COALESCE(r.wr_return_amt, 0)) AS total_returns,
    SUM(s.ws_net_profit) - SUM(COALESCE(r.wr_return_amt, 0)) AS net_after_returns,
    COUNT(DISTINCT s.ws_order_number) AS orders_cnt,
    ROW_NUMBER() OVER (PARTITION BY wh.w_warehouse_name ORDER BY SUM(s.ws_ext_sales_price) DESC) AS sales_rank
FROM web_sales s
JOIN time_dim td_sold
    ON s.ws_sold_time_sk = td_sold.t_time_sk
JOIN item i_sold
    ON s.ws_item_sk = i_sold.i_item_sk
JOIN customer_demographics cd_bill
    ON s.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON s.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_site ws_site
    ON s.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse wh
    ON s.ws_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN web_returns r
    ON s.ws_order_number = r.wr_order_number
LEFT JOIN time_dim td_returned
    ON r.wr_returned_time_sk = td_returned.t_time_sk
LEFT JOIN item i_return
    ON r.wr_item_sk = i_return.i_item_sk
LEFT JOIN customer_demographics cd_refunded
    ON r.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns r2
    WHERE r2.wr_order_number = s.ws_order_number
      AND r2.wr_return_amt > 100
)
GROUP BY
    wh.w_warehouse_name,
    ws_site.web_name,
    i_sold.i_category,
    cd_bill.cd_gender,
    cd_ship.cd_gender
HAVING SUM(s.ws_ext_sales_price) > 1000
ORDER BY net_after_returns DESC
LIMIT 100
