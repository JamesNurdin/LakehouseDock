WITH order_profit AS (
    SELECT
        cs.cs_order_number AS order_number,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_quantity > 5
)
SELECT
    bill_state,
    COUNT(DISTINCT order_number) AS total_orders,
    AVG(net_profit) AS avg_net_profit,
    SUM(CASE WHEN bill_state = ship_state THEN net_profit ELSE 0 END) AS intra_state_profit,
    (SUM(CASE WHEN bill_state = ship_state THEN net_profit ELSE 0 END) / NULLIF(SUM(net_profit), 0)) AS intra_state_ratio,
    ROW_NUMBER() OVER (ORDER BY AVG(net_profit) DESC) AS profit_state_rank,
    CASE
        WHEN AVG(net_profit) > 50000 THEN 'Very High'
        WHEN AVG(net_profit) BETWEEN 25000 AND 50000 THEN 'High'
        WHEN AVG(net_profit) BETWEEN 10000 AND 25000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM order_profit
GROUP BY bill_state
ORDER BY profit_state_rank
LIMIT 5
