WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        td.t_hour,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE td.t_hour BETWEEN 9 AND 17
)
SELECT
    t_hour,
    bill_state,
    ship_state,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    SUM(cs_quantity) AS total_qty,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_ext_discount_amt) AS total_discount,
    SUM(cs_net_paid) AS total_net_paid,
    CASE WHEN SUM(cs_ext_sales_price) = 0 THEN NULL
         ELSE ROUND(SUM(cs_ext_discount_amt) / SUM(cs_ext_sales_price), 4)
    END AS discount_rate,
    CASE WHEN bill_state = ship_state THEN 'Match' ELSE 'Mismatch' END AS address_match_flag
FROM sales_detail
GROUP BY
    t_hour,
    bill_state,
    ship_state,
    CASE WHEN bill_state = ship_state THEN 'Match' ELSE 'Mismatch' END
ORDER BY
    t_hour,
    bill_state,
    ship_state
