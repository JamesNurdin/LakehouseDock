WITH order_profit AS (
    SELECT
        cs.cs_order_number AS order_number,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
)
SELECT
    ship_state,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(net_profit) AS total_net_profit,
    SUM(CASE WHEN bill_state <> ship_state THEN net_profit ELSE 0 END) AS cross_state_profit,
    (SUM(CASE WHEN bill_state <> ship_state THEN net_profit ELSE 0 END) / NULLIF(SUM(net_profit), 0)) AS cross_state_ratio,
    RANK() OVER (ORDER BY SUM(net_profit) DESC) AS profit_state_rank,
    CASE
        WHEN SUM(net_profit) > 200000 THEN 'Very High'
        WHEN SUM(net_profit) BETWEEN 100000 AND 200000 THEN 'High'
        WHEN SUM(net_profit) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM order_profit
GROUP BY ship_state
ORDER BY profit_state_rank
LIMIT 10
