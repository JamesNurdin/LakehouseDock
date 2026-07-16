WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_ext_ship_cost
    FROM web_sales ws
    WHERE ws.ws_net_profit > 0
      AND ws.ws_ext_discount_amt > 0
)
SELECT
    ca_bill.ca_city AS bill_city,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_city AS ship_city,
    ca_ship.ca_state AS ship_state,
    t.t_hour,
    hd_ship.hd_vehicle_count,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    SUM(fs.ws_net_profit) AS total_net_profit,
    AVG(fs.ws_quantity) AS avg_quantity,
    COUNT(*) AS num_transactions,
    RANK() OVER (PARTITION BY ca_bill.ca_state ORDER BY SUM(fs.ws_net_profit) DESC) AS profit_rank_state
FROM filtered_sales fs
JOIN time_dim t ON fs.ws_sold_time_sk = t.t_time_sk
JOIN household_demographics hd_ship ON fs.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill ON fs.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON fs.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE
    ca_bill.ca_state IN ('CA', 'TX', 'NY')
    AND ca_bill.ca_gmt_offset = -7.00
    AND t.t_shift = 'Evening'
    AND hd_ship.hd_vehicle_count >= 2
GROUP BY
    ca_bill.ca_city,
    ca_bill.ca_state,
    ca_ship.ca_city,
    ca_ship.ca_state,
    t.t_hour,
    hd_ship.hd_vehicle_count
HAVING
    SUM(fs.ws_quantity) > 100
ORDER BY
    total_net_profit DESC
LIMIT 50
