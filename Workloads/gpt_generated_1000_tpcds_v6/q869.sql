WITH rs AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        hd_return.hd_buy_potential,
        ca_return.ca_county AS return_county,
        td_return.t_hour AS return_hour
    FROM store_returns sr
    JOIN household_demographics hd_return
        ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
    JOIN customer_address ca_return
        ON sr.sr_addr_sk = ca_return.ca_address_sk
    JOIN time_dim td_return
        ON sr.sr_return_time_sk = td_return.t_time_sk
    WHERE hd_return.hd_buy_potential = '1001-5000'
)
SELECT
    ca_bill.ca_county AS billing_county,
    sm.sm_carrier,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    AVG(ws.ws_quantity) AS avg_quantity
FROM web_sales ws
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN time_dim td_sold
    ON ws.ws_sold_time_sk = td_sold.t_time_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE hd_bill.hd_buy_potential = '>10000'
  AND hd_ship.hd_dep_count >= 2
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ws.ws_item_sk
          AND sr2.sr_returned_date_sk = ws.ws_sold_date_sk
    )
GROUP BY ca_bill.ca_county, sm.sm_carrier
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
