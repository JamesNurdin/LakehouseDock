-- Analytical query: total and average profit per catalog department by billing and shipping state
WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_catalog_number,
        bill.ca_state AS bill_state,
        ship.ca_state AS ship_state
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address bill
        ON cs.cs_bill_addr_sk = bill.ca_address_sk
    JOIN customer_address ship
        ON cs.cs_ship_addr_sk = ship.ca_address_sk
)
SELECT
    cp_department,
    bill_state,
    ship_state,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cs_net_profit) AS avg_net_profit
FROM sales_detail
GROUP BY cp_department, bill_state, ship_state
HAVING SUM(cs_quantity) > 200
ORDER BY total_net_profit DESC
LIMIT 15
