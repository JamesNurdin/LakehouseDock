SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    cd_refunded.cd_gender,
    ca_refunded.ca_state,
    ca_refunded.ca_zip,
    sm.sm_type,
    sm.sm_carrier,
    w.w_warehouse_name,
    w.w_state,
    r.r_reason_desc,
    ws.ws_order_number,
    ws.ws_ext_discount_amt,
    ws.ws_ext_sales_price,
    ws.ws_quantity,
    p.p_promo_name,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_amount_category,
    RANK() OVER (PARTITION BY w.w_state ORDER BY cr.cr_return_amount DESC) AS state_return_amount_rank,
    (SELECT AVG(ws2.ws_quantity)
       FROM web_sales ws2
      WHERE ws2.ws_bill_customer_sk = ws.ws_bill_customer_sk
        AND ws2.ws_sold_date_sk > ws.ws_sold_date_sk) AS avg_future_quantity
FROM catalog_returns cr
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
CROSS JOIN LATERAL (
    SELECT ca_address_sk, ca_state, ca_zip, ca_city
    FROM customer_address ca
    WHERE ca.ca_address_sk = cr.cr_refunded_addr_sk
) ca_refunded
JOIN web_sales ws
  ON ws.ws_bill_cdemo_sk = cd_refunded.cd_demo_sk
 AND ws.ws_bill_addr_sk = ca_refunded.ca_address_sk
 AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
WHERE cd_refunded.cd_gender = 'M'
  AND ca_refunded.ca_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'TX'
  AND ws.ws_ext_discount_amt > 500
  AND cr.cr_return_quantity > 0
  AND p.p_discount_active = 'Y'
  AND cr.cr_order_number NOT IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_order_number IS NOT NULL)
LIMIT 100
