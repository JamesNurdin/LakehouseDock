WITH cr_ws AS (
   SELECT
       cr.cr_order_number,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_amt_inc_tax,
       cr.cr_fee,
       cr.cr_return_ship_cost,
       cr.cr_net_loss,
       i.i_category,
       i.i_brand,
       i.i_current_price,
       cc.cc_name,
       cp.cp_department,
       sm.sm_type,
       sm.sm_contract,
       w.w_warehouse_name,
       ws.ws_quantity,
       ws.ws_sales_price,
       ws.ws_ext_sales_price,
       ws.ws_net_paid,
       ws.ws_net_profit
   FROM catalog_returns cr
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
   WHERE cc.cc_state = 'CA'
     AND cp.cp_department = 'Books'
     AND sm.sm_contract = 'UaAJjKDnL4gTOqbpj'
     AND w.w_state = 'TX'
)
SELECT
   i_category,
   i_brand,
   w_warehouse_name,
   sm_type,
   orders,
   total_return_qty,
   total_return_amount,
   total_net_profit,
   ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM (
   SELECT
       i_category,
       i_brand,
       w_warehouse_name,
       sm_type,
       COUNT(DISTINCT cr_order_number) AS orders,
       SUM(cr_return_quantity) AS total_return_qty,
       SUM(cr_return_amount) AS total_return_amount,
       SUM(ws_net_profit) AS total_net_profit
   FROM cr_ws
   GROUP BY i_category, i_brand, w_warehouse_name, sm_type
) agg
ORDER BY total_return_amount DESC
LIMIT 100
