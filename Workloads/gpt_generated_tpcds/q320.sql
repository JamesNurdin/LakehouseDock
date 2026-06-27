SELECT
    i.i_category,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(CASE WHEN d_return.d_year = 2022 THEN wr.wr_return_amt ELSE 0 END) AS total_return_amount,
    SUM(CASE WHEN d_return.d_year = 2022 THEN wr.wr_return_quantity ELSE 0 END) AS total_return_quantity,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
        ELSE SUM(CASE WHEN d_return.d_year = 2022 THEN wr.wr_return_amt ELSE 0 END) / SUM(ws.ws_ext_sales_price)
    END AS return_amount_ratio
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    i.i_category,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_category,
    wp.wp_type
