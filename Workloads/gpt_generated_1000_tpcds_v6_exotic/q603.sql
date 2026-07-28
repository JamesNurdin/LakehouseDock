WITH sales_with_addresses AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ship_customer_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_ext_list_price,
        ca_bill.ca_state AS bill_state,
        ca_bill.ca_county AS bill_county,
        ca_ship.ca_state AS ship_state,
        ca_ship.ca_county AS ship_county,
        ca_ship.ca_street_type AS ship_street_type
    FROM tpcds.catalog_sales AS cs
    INNER JOIN tpcds.customer_address AS ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN tpcds.customer_address AS ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_ship_customer_sk = 10379558
      AND cs.cs_net_paid_inc_ship > 1000
      AND cs.cs_ext_list_price BETWEEN 1000 AND 5000
      AND ca_bill.ca_state = 'CA'
      AND ca_bill.ca_county = 'Williams County'
      AND ca_ship.ca_street_type = 'Rd'
)
SELECT
    bill_state,
    ship_state,
    ship_county,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(cs_ext_list_price) AS avg_ext_list_price,
    MIN(cs_ext_list_price) AS min_ext_list_price,
    MAX(cs_ext_list_price) AS max_ext_list_price
FROM sales_with_addresses
GROUP BY bill_state, ship_state, ship_county
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
