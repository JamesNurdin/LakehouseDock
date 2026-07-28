WITH refunded AS (
    SELECT DISTINCT
        cr.cr_order_number AS order_number,
        cd.cd_gender AS gender,
        cr.cr_refunded_cash AS amount,
        w.w_warehouse_name AS warehouse_name,
        w.w_warehouse_sk
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_refunded_cash > 100
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_warehouse_sk = w.w_warehouse_sk
            AND i.inv_quantity_on_hand > 0
      )
),
web AS (
    SELECT DISTINCT
        ws.ws_order_number AS order_number,
        cd.cd_gender AS gender,
        ws.ws_ext_sales_price AS amount,
        w.w_warehouse_name AS warehouse_name,
        w.w_warehouse_sk
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_ext_sales_price > 500
      AND p.p_channel_email = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_warehouse_sk = w.w_warehouse_sk
            AND i.inv_quantity_on_hand > 0
      )
)
SELECT order_number,
       gender,
       amount,
       warehouse_name
FROM (
    SELECT order_number, gender, amount, warehouse_name FROM refunded
    UNION ALL
    SELECT order_number, gender, amount, warehouse_name FROM web
) AS combined
ORDER BY amount DESC
LIMIT 100
