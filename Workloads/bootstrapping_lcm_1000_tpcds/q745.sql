SELECT
    d_ret.d_year AS return_year,
    d_ws.d_year AS sale_year,
    s.s_city,
    CASE
        WHEN c.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS birth_quarter,
    d_cust_ship.d_year AS first_ship_year,
    d_cust_sales.d_year AS first_sales_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    COUNT(DISTINCT ws.ws_order_number) AS num_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_net_paid), 0) > 0.2 THEN 'High Profit'
        WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_net_paid), 0) > 0.1 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d_cust_ship ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_cust_sales ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ws.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ws.d_year,
    s.s_city,
    CASE
        WHEN c.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN c.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN c.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    d_cust_ship.d_year,
    d_cust_sales.d_year
ORDER BY total_return_amount DESC
LIMIT 100
