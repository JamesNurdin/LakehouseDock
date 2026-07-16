SELECT
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    d_return.d_year AS return_year,
    d_return.d_moy AS return_month,
    d_return.d_date AS return_date,
    ca_refund.ca_city AS refund_city,
    ca_returning.ca_city AS returning_city,
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales_price,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_fee) AS total_fee,
    AVG(cs.cs_quantity) AS avg_quantity,
    (SUM(cs.cs_net_paid) - SUM(cr.cr_return_amount) - SUM(cr.cr_fee)) AS net_revenue
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE cs.cs_net_paid > 0
GROUP BY
    s.s_store_name,
    s.s_city,
    d_return.d_year,
    d_return.d_moy,
    d_return.d_date,
    ca_refund.ca_city,
    ca_returning.ca_city,
    ca_bill.ca_city,
    ca_ship.ca_city
ORDER BY total_net_profit DESC
LIMIT 100
