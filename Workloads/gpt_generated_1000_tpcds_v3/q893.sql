WITH ws_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_ship_mode_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_list_price,
        ws.ws_ext_list_price,
        ws.ws_ext_sales_price
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_tax > 100
      AND ws.ws_quantity >= 2
      AND ws.ws_list_price >= 50
      AND ws.ws_ext_list_price < 20000
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    sm.sm_code,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    CASE
        WHEN ws.ws_net_profit > 5000 THEN 'HIGH'
        WHEN ws.ws_net_profit > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY i.i_category ORDER BY ws.ws_net_profit DESC) AS category_profit_rank,
    AVG(ws.ws_net_paid) OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS avg_net_paid_last_4
FROM ws_detail ws
INNER JOIN tpcds.item i
    ON ws.ws_item_sk = i.i_item_sk
INNER JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN tpcds.customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
INNER JOIN tpcds.customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE i.i_category = 'Electronics'
  AND sm.sm_type = 'EXPRESS'
  AND ca_bill.ca_state = 'CA'
  AND ca_ship.ca_state = 'NY'
ORDER BY ws.ws_net_profit DESC
LIMIT 100
