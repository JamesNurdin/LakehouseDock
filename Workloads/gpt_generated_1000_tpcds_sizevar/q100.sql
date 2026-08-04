WITH diff_orders AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT ws_order_number FROM web_sales
)
SELECT
    w.w_warehouse_id,
    cc.cc_name,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SELECT COUNT(*) FROM diff_orders) AS catalog_not_in_web_orders
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE c.c_birth_day = 15
  AND cc.cc_state = 'CA'
  AND p.p_channel_dmail = 'Y'
  AND hd.hd_buy_potential = '1001-5000'
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND EXISTS (
        SELECT 1 FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = c.c_current_cdemo_sk
          AND cd2.cd_purchase_estimate > 5000
      )
  AND wr.wr_return_quantity > 0
  AND inv.inv_quantity_on_hand > 0
GROUP BY
    w.w_warehouse_id,
    cc.cc_name,
    p.p_promo_name
ORDER BY catalog_profit DESC
LIMIT 100
