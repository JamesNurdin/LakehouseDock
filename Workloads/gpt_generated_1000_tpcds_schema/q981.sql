WITH
ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_ext_list_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        d.d_year,
        d.d_quarter_seq,
        ca_bill.ca_address_sk AS bill_addr_sk,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_address_sk AS ship_addr_sk,
        ca_ship.ca_state AS ship_state,
        w.w_warehouse_sk,
        w.w_state AS warehouse_state
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca_bill
      ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
      ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND ws.ws_ext_list_price > 5000
      AND w.w_state = 'CA'
      AND ca_bill.ca_state = 'NY'
      AND ca_ship.ca_state = 'TX'
      AND ws.ws_quantity > 2
),
high_profit_orders AS (
    SELECT ws_order_number
    FROM ws_base
    WHERE ws_net_profit > 1000
),
low_profit_orders AS (
    SELECT ws_order_number
    FROM ws_base
    WHERE ws_net_profit < 0
),
intersect_orders AS (
    SELECT ws_order_number FROM high_profit_orders
    INTERSECT
    SELECT ws_order_number FROM low_profit_orders
),
except_orders AS (
    SELECT ws_order_number FROM high_profit_orders
    EXCEPT
    SELECT ws_order_number FROM low_profit_orders
),
aggregated AS (
    SELECT
        d_year,
        warehouse_state,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_list_price) AS avg_list_price,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        COUNT(DISTINCT bill_addr_sk) AS distinct_bill_addresses,
        MIN(ws_ext_discount_amt) AS min_discount,
        MAX(l.max_fee) AS max_return_fee,
        (SELECT COUNT(*) FROM intersect_orders) AS intersect_order_cnt,
        (SELECT COUNT(*) FROM except_orders) AS except_order_cnt
    FROM ws_base wb
    LEFT JOIN LATERAL (
        SELECT
            MAX(sr.sr_fee) AS max_fee
        FROM tpcds.store_returns sr
        WHERE sr.sr_addr_sk = wb.bill_addr_sk
          AND sr.sr_returned_date_sk = wb.ws_sold_date_sk
    ) l ON TRUE
    GROUP BY d_year, warehouse_state
)
SELECT *
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
