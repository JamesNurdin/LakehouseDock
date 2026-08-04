WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        cc.cc_name,
        cc.cc_state,
        w.w_warehouse_name,
        w.w_state,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        p.p_promo_id
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_country = 'United States'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    cs_base.cs_order_number,
    cs_base.cs_net_paid,
    cs_base.i_item_id,
    cs_base.cc_name,
    cs_base.w_warehouse_name,
    ROW_NUMBER() OVER (PARTITION BY cs_base.cs_bill_customer_sk ORDER BY cs_base.cs_net_paid DESC) AS rn_customer,
    (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_item_sk = cs_base.cs_item_sk) AS avg_item_sales_price,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_order_number = cs_base.cs_order_number
              AND cr.cr_return_quantity > 0
        ) THEN 'Returned'
        ELSE 'Fullfilled'
    END AS return_status,
    sr.sr_return_quantity,
    ws.ws_sales_price
FROM cs_base
JOIN inventory inv
    ON inv.inv_item_sk = cs_base.cs_item_sk
   AND inv.inv_warehouse_sk = cs_base.cs_warehouse_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_item_sk = cs_base.cs_item_sk
   AND sr.sr_return_time_sk = cs_base.cs_sold_time_sk
FULL OUTER JOIN web_sales ws
    ON ws.ws_item_sk = cs_base.cs_item_sk
   AND ws.ws_sold_time_sk = cs_base.cs_sold_time_sk
WHERE (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
  AND (ws.ws_quantity IS NULL OR ws.ws_quantity > 1)
  AND cs_base.cs_quantity > 0
  AND cs_base.cs_net_profit > 0
  AND cs_base.cs_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    cs_base.cs_order_number,
    cs_base.cs_net_paid,
    cs_base.i_item_id,
    cs_base.cc_name,
    cs_base.w_warehouse_name,
    cs_base.cs_bill_customer_sk,
    cs_base.cs_item_sk,
    sr.sr_return_quantity,
    ws.ws_sales_price
HAVING COUNT(*) FILTER (WHERE sr.sr_return_quantity IS NOT NULL) < 5
INTERSECT
SELECT
    cr.cr_order_number,
    cr.cr_refunded_cash,
    i.i_item_id,
    cc.cc_name,
    w.w_warehouse_name,
    ROW_NUMBER() OVER (PARTITION BY cr.cr_refunded_customer_sk ORDER BY cr.cr_refunded_cash DESC),
    (SELECT AVG(ws3.ws_sales_price) FROM web_sales ws3 WHERE ws3.ws_item_sk = i.i_item_sk),
    'Returned' AS return_status,
    cr.cr_return_quantity,
    NULL AS ws_sales_price
FROM catalog_returns cr
JOIN catalog_sales cs2 ON cr.cr_order_number = cs2.cs_order_number
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_quantity > 0
  AND cc.cc_state = 'CA'
  AND w.w_state = 'CA'
  AND i.i_category = 'Sports'
  AND cr.cr_return_amount > 100
  AND cr.cr_return_tax < 50
LIMIT 100
