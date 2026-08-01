WITH sampled_sales AS (
        SELECT
            cs_order_number,
            cs_sold_date_sk,
            cs_bill_addr_sk,
            cs_ship_addr_sk,
            cs_call_center_sk,
            cs_quantity,
            cs_net_profit,
            cs_net_paid
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    high_profit_orders AS (
        SELECT cs_order_number
        FROM sampled_sales
        WHERE cs_net_profit > 100
    ),
    higher_profit_orders AS (
        SELECT cs_order_number
        FROM sampled_sales
        WHERE cs_net_profit > 200
    ),
    filtered_orders AS (
        SELECT cs_order_number
        FROM high_profit_orders
        EXCEPT
        SELECT cs_order_number FROM higher_profit_orders
    )
SELECT
    s.cs_order_number,
    d_sold.d_date AS sold_date,
    cc.cc_name AS call_center_name,
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    s.cs_quantity,
    s.cs_net_profit,
    i.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY cc.cc_name ORDER BY s.cs_net_profit DESC) AS profit_rank_by_cc,
    ROW_NUMBER() OVER (ORDER BY s.cs_net_paid DESC) AS global_row_num
FROM sampled_sales AS s
JOIN date_dim AS d_sold
    ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center AS cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_address AS ca_bill
    ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address AS ca_ship
    ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN inventory AS i
    ON i.inv_date_sk = d_sold.d_date_sk
WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND cc.cc_state = 'CA'
  AND ca_bill.ca_state = 'TX'
  AND s.cs_quantity > 5
  AND s.cs_net_profit > 0
  AND i.inv_quantity_on_hand < 100
  AND i.inv_warehouse_sk IN (4, 6, 12)
  AND s.cs_order_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity = 1
    )
  AND s.cs_order_number IN (SELECT cs_order_number FROM filtered_orders)
ORDER BY global_row_num
LIMIT 100
