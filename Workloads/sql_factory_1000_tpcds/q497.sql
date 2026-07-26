WITH order_profit AS (
    SELECT
        cs.cs_order_number AS order_number,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_tax AS tax_amount,
        cs.cs_ext_ship_cost AS ship_cost
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_ext_tax > 0
)
SELECT
    ship_state,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(net_profit) AS total_net_profit,
    AVG(tax_amount) AS avg_tax,
    AVG(ship_cost) AS avg_ship_cost,
    SUM(CASE WHEN bill_state <> ship_state THEN net_profit ELSE 0 END) AS cross_state_profit,
    (SUM(CASE WHEN bill_state <> ship_state THEN net_profit ELSE 0 END) / NULLIF(SUM(net_profit), 0)) AS cross_state_ratio,
    ROW_NUMBER() OVER (PARTITION BY ship_state ORDER BY SUM(net_profit) DESC) AS state_order_rank,
    CASE
        WHEN SUM(net_profit) > 150000 THEN 'Elite'
        WHEN SUM(net_profit) BETWEEN 75000 AND 150000 THEN 'Strong'
        ELSE 'Weak'
    END AS profit_tier
FROM order_profit
GROUP BY ship_state
HAVING COUNT(*) >= 10
ORDER BY state_order_rank
LIMIT 10
