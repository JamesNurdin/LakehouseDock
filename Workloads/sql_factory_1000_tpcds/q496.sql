WITH order_profit AS (
    SELECT
        cs.cs_order_number AS order_number,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cs.cs_net_profit AS net_profit,
        cs.cs_sales_price * cs.cs_quantity AS gross_sales
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cs.cs_ship_mode_sk IN (1, 2, 3)
)
SELECT
    ship_state,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(gross_sales) AS total_gross_sales,
    SUM(net_profit) AS total_net_profit,
    SUM(CASE WHEN bill_state <> ship_state THEN net_profit ELSE 0 END) AS cross_state_profit,
    (SUM(CASE WHEN bill_state <> ship_state THEN net_profit ELSE 0 END) / NULLIF(SUM(net_profit), 0)) AS cross_state_ratio,
    DENSE_RANK() OVER (ORDER BY SUM(gross_sales) DESC) AS sales_rank,
    CASE
        WHEN SUM(gross_sales) > 1000000 THEN 'Top Tier'
        WHEN SUM(gross_sales) BETWEEN 500000 AND 1000000 THEN 'High Tier'
        ELSE 'Standard'
    END AS sales_category
FROM order_profit
GROUP BY ship_state
ORDER BY sales_rank
LIMIT 8
