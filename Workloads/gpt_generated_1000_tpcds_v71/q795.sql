WITH ws_agg AS (
    SELECT
        ws.ws_promo_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
    GROUP BY ws.ws_promo_sk, ws.ws_item_sk
)
SELECT
    p.p_promo_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    ca_bill.ca_state        AS bill_state,
    ca_ship.ca_state        AS ship_state,
    cd_bill.cd_gender,
    SUM(ss.ss_ext_sales_price)      AS store_sales_amount,
    SUM(ws_agg.total_net_profit)    AS web_total_profit,
    COUNT(DISTINCT ws_agg.ws_item_sk) AS distinct_items_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity
FROM store_sales ss
JOIN customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN customer_address ca_store
    ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN ws_agg
    ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_promo_sk = ws_agg.ws_promo_sk
   AND ws.ws_item_sk = ws_agg.ws_item_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site site
    ON ws.ws_web_site_sk = site.web_site_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE p.p_channel_email = 'Y'
  AND sm.sm_carrier = 'MSC'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    p.p_promo_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    ca_bill.ca_state,
    ca_ship.ca_state,
    cd_bill.cd_gender
HAVING SUM(ws_agg.total_net_profit) > 10000
ORDER BY store_sales_amount DESC
LIMIT 100
