WITH joined_data AS (
    SELECT
        ws.ws_order_number                         AS order_number,
        ws.ws_net_paid_inc_ship_tax                AS net_paid_inc_ship_tax,
        ws.ws_coupon_amt                           AS coupon_amt,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        w.w_state                                   AS warehouse_state,
        w.w_city                                    AS warehouse_city,
        s.s_state                                   AS store_state,
        s.s_city                                    AS store_city,
        ca_bill.ca_state                            AS bill_state,
        ca_bill.ca_country                          AS bill_country,
        wsit.web_name,
        r_wr.r_reason_id                           AS web_return_reason_id,
        wr.wr_return_amt                           AS return_amt,
        r_sr.r_reason_id                           AS store_return_reason_id,
        sr.sr_return_amt                           AS sr_return_amt,
        sr.sr_net_loss
    FROM web_sales ws
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_addr_sk = ca_bill.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ws.ws_net_paid_inc_ship_tax > 1000
      AND ws.ws_coupon_amt BETWEEN 50 AND 2000
      AND w.w_state = 'CA'
      AND ca_bill.ca_country = 'United States'
      AND r_wr.r_reason_id = 'AAAAAAAADAAAAAAA'
      AND s.s_state = 'TX'
)
SELECT
    warehouse_state,
    store_state,
    bill_state,
    web_name,
    COUNT(DISTINCT order_number)                                    AS total_orders,
    SUM(net_paid_inc_ship_tax)                                      AS total_net_paid,
    AVG(coupon_amt)                                                 AS avg_coupon,
    MIN(net_paid_inc_ship_tax)                                      AS min_net_paid,
    MAX(net_paid_inc_ship_tax)                                      AS max_net_paid,
    SUM(CASE WHEN web_return_reason_id = 'AAAAAAAADAAAAAAA' THEN return_amt ELSE 0 END) AS total_web_return_for_reason,
    SUM(CASE WHEN store_return_reason_id = 'AAAAAAAALAAAAAAA' THEN sr_return_amt ELSE 0 END) AS total_store_return_for_reason
FROM joined_data
GROUP BY
    warehouse_state,
    store_state,
    bill_state,
    web_name
ORDER BY total_net_paid DESC
LIMIT 100
