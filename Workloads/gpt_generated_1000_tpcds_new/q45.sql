WITH store_sales_agg AS (
    SELECT ss_item_sk,
           ss_promo_sk,
           SUM(ss_net_profit) AS store_profit
    FROM store_sales
    WHERE ss_quantity > 0
      AND ss_sold_time_sk IN (
          SELECT t_time_sk
          FROM time_dim
          WHERE t_hour BETWEEN 9 AND 17
      )
    GROUP BY ss_item_sk, ss_promo_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       w.w_warehouse_name,
       SUM(sa.store_profit)               AS total_store_profit,
       SUM(cs.cs_net_profit)              AS total_catalog_profit,
       SUM(ws.ws_net_profit)              AS total_web_profit,
       SUM(inv.inv_quantity_on_hand)      AS total_inventory,
       COUNT(DISTINCT cr.cr_order_number) AS return_cnt
FROM   store_sales_agg sa
JOIN   item i
       ON sa.ss_item_sk = i.i_item_sk
JOIN   promotion p
       ON sa.ss_promo_sk = p.p_promo_sk
JOIN   catalog_sales cs
       ON cs.cs_item_sk = i.i_item_sk
JOIN   call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN   customer_demographics cd
       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN   inventory inv
       ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN   web_sales ws
       ON ws.ws_item_sk = i.i_item_sk
JOIN   web_site ws_site
       ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN catalog_returns cr
       ON cr.cr_item_sk = i.i_item_sk
      AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r
       ON cr.cr_reason_sk = r.r_reason_sk
JOIN   time_dim td
       ON cs.cs_sold_time_sk = td.t_time_sk
WHERE  i.i_current_price > 5.0
  AND  i.i_color = 'Red'
  AND  p.p_discount_active = 'Y'
  AND  cc.cc_state = 'CA'
  AND  r.r_reason_desc LIKE '%Gift%'
  AND  td.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM   catalog_returns cr2
        WHERE  cr2.cr_item_sk = i.i_item_sk
          AND  cr2.cr_return_amount > 200
      )
GROUP BY i.i_item_id,
         i.i_product_name,
         w.w_warehouse_name
ORDER BY total_store_profit DESC
LIMIT 100
