WITH agg_sales AS (
    SELECT
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_wholesale_cost > 20
      AND cs.cs_net_paid_inc_ship BETWEEN 100 AND 5000
      AND c_bill.c_salutation = 'Mr.'
      AND ca_bill.ca_country = 'United States'
      AND ca_ship.ca_state IN ('CA', 'TX', 'NY')
      AND cs.cs_ship_hdemo_sk IN (4375, 5128, 2685)
    GROUP BY ca_bill.ca_state, ca_ship.ca_state
)
SELECT
    bill_state,
    ship_state,
    SUM(total_net_paid) AS sum_net_paid,
    SUM(total_profit) AS sum_profit,
    SUM(order_cnt) AS total_orders
FROM agg_sales
GROUP BY GROUPING SETS ((bill_state, ship_state), (bill_state), ())
ORDER BY bill_state
LIMIT 100
