WITH filtered_sales AS (
    SELECT
        cs.*, 
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        sm.sm_type,
        sm.sm_carrier,
        sm.sm_ship_mode_id
    FROM catalog_sales cs
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_profit > 0
      AND cs.cs_ship_addr_sk IN (5184251, 2121279)
      AND sm.sm_type = 'AIR'
)
SELECT
    sm_ship_mode_id,
    bill_state,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_discount_amt) AS total_discount,
    AVG(cs_quantity) AS avg_quantity,
    SUM(cs_net_paid) AS total_net_paid,
    (SUM(cs_net_profit) / NULLIF(SUM(cs_quantity), 0)) AS profit_per_unit,
    RANK() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
FROM filtered_sales
GROUP BY sm_ship_mode_id, bill_state
HAVING SUM(cs_net_profit) > 1000
ORDER BY total_net_profit DESC
