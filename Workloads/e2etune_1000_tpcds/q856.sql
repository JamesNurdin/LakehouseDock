SELECT
    ca_bill.ca_state AS billing_state,
    COUNT(*) AS order_count,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_list_price), 0) AS discount_rate,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS profit_margin,
    ARRAY_AGG(DISTINCT ca_ship.ca_state) AS shipping_states
FROM
    catalog_sales cs
JOIN
    customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN
    customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE
    cs.cs_quantity >= 20
    AND cs.cs_sales_price > 50
    AND cs.cs_ext_wholesale_cost > 2000
GROUP BY
    ca_bill.ca_state
HAVING
    SUM(cs.cs_net_profit) > 1000
ORDER BY
    total_profit DESC
LIMIT 10
