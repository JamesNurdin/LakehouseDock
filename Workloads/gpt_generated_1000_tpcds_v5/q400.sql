WITH agg_returns AS (
    SELECT
        cr_ship_mode_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    GROUP BY cr_ship_mode_sk
)
SELECT
    sm.sm_type AS ship_mode_type,
    cc.cc_name AS call_center_name,
    d_sold.d_year AS sales_year,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ar.total_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer cust_bill
    ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship
    ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN agg_returns ar
    ON sm.sm_ship_mode_sk = ar.cr_ship_mode_sk
JOIN catalog_returns cr
    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
WHERE d_sold.d_year BETWEEN 2001 AND 2002
GROUP BY sm.sm_type, cc.cc_name, d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
