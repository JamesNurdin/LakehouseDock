SELECT
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month_seq,
    t_time.t_hour AS return_hour,
    ws.web_mkt_desc AS market_desc,
    COUNT(DISTINCT cust.c_customer_sk) AS num_customers,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM tpcds.store_returns sr
JOIN tpcds.date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.time_dim t_time
    ON sr.sr_return_time_sk = t_time.t_time_sk
JOIN tpcds.customer cust
    ON sr.sr_customer_sk = cust.c_customer_sk
JOIN tpcds.date_dim d_ship
    ON cust.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN tpcds.date_dim d_sales
    ON cust.c_first_sales_date_sk = d_sales.d_date_sk
JOIN tpcds.date_dim d_review
    ON cust.c_last_review_date = d_review.d_date_sk
JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d_ship.d_date_sk
JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d_return.d_date_sk
JOIN tpcds.date_dim d_close
    ON ws.web_close_date_sk = d_close.d_date_sk
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    t_time.t_hour,
    ws.web_mkt_desc
HAVING
    SUM(sr.sr_return_amt) > 1000
ORDER BY
    total_return_amount DESC
LIMIT 100
