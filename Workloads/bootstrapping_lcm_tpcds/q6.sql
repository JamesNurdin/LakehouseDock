SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    ca_bill.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    st.s_market_id,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFITABLE'
        ELSE 'LOSS'
    END AS profit_status
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
  AND ca_bill.ca_country = 'United States'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    ca_bill.ca_state,
    ca_ship.ca_state,
    st.s_market_id
HAVING SUM(cs.cs_net_paid_inc_tax) > 100000
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
