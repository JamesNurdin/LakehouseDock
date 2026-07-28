WITH item_inventory AS (
   SELECT
       i.i_item_sk,
       i.i_item_id,
       i.i_category_id,
       i.i_manufact_id,
       AVG(inv.inv_quantity_on_hand) AS avg_inv_qty
   FROM item i
   JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk, i.i_item_id, i.i_category_id, i.i_manufact_id
   HAVING COUNT(DISTINCT inv.inv_warehouse_sk) >= 2
),
sales_join AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_warehouse_sk,
       cs.cs_call_center_sk,
       cs.cs_ship_mode_sk,
       cs.cs_promo_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       ws.ws_quantity,
       ws.ws_net_paid,
       cd.cd_gender,
       p.p_discount_active,
       w.w_state,
       cc.cc_name
   FROM catalog_sales cs
   JOIN web_sales ws
     ON cs.cs_order_number = ws.ws_order_number
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE p.p_discount_active = 'Y'
)
SELECT
   ii.i_item_id,
   ii.i_category_id,
   ii.i_manufact_id,
   sj.w_state,
   sj.cc_name,
   COUNT(DISTINCT sj.cs_item_sk) AS distinct_item_cnt,
   SUM(sj.cs_quantity + sj.ws_quantity) AS total_units_sold,
   SUM(sj.cs_net_paid + sj.ws_net_paid) AS total_sales,
   AVG(ii.avg_inv_qty) AS avg_inventory_qty,
   CASE
       WHEN SUM(sj.cs_net_paid + sj.ws_net_paid) > 200000 THEN 'High'
       WHEN SUM(sj.cs_net_paid + sj.ws_net_paid) > 100000 THEN 'Medium'
       ELSE 'Low'
   END AS sales_tier,
   RANK() OVER (ORDER BY SUM(sj.cs_net_paid + sj.ws_net_paid) DESC) AS sales_rank
FROM item_inventory ii
JOIN sales_join sj
  ON sj.cs_item_sk = ii.i_item_sk
WHERE ii.i_category_id = 4
  AND sj.w_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = ii.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY
   ii.i_item_id,
   ii.i_category_id,
   ii.i_manufact_id,
   sj.w_state,
   sj.cc_name
ORDER BY total_sales DESC
LIMIT 100
