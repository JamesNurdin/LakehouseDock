WITH base AS (
   SELECT
      cr.cr_return_amount,
      cr.cr_return_quantity,
      ws.ws_ext_sales_price,
      ws.ws_quantity,
      i.i_category,
      i.i_category_id,
      i.i_current_price,
      w.w_warehouse_name,
      w.w_state,
      sm.sm_type,
      ca_ref.ca_gmt_offset,
      CASE
         WHEN i.i_wholesale_cost > 10 THEN 'HIGH_COST'
         ELSE 'LOW_COST'
      END AS cost_category
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
                     AND ws.ws_bill_addr_sk = ca_ref.ca_address_sk
   WHERE i.i_category_id = 2
     AND w.w_state = 'CA'
     AND ca_ref.ca_gmt_offset >= -8
     AND ws.ws_quantity >= 5
     AND EXISTS (
         SELECT 1 FROM catalog_returns cr2
         WHERE cr2.cr_item_sk = i.i_item_sk
           AND cr2.cr_return_quantity > 3
     )
)
SELECT
   i_category,
   i_category_id,
   w_warehouse_name,
   w_state,
   sm_type,
   cost_category,
   SUM(cr_return_amount) AS total_return_amount,
   SUM(ws_ext_sales_price) AS total_sales_amount,
   COUNT(*) AS txn_count,
   RANK() OVER (PARTITION BY w_state ORDER BY SUM(cr_return_amount) DESC) AS state_return_rank
FROM base
GROUP BY
   i_category,
   i_category_id,
   w_warehouse_name,
   w_state,
   sm_type,
   cost_category
HAVING SUM(cr_return_amount) > 500
ORDER BY total_return_amount DESC, state_return_rank ASC
LIMIT 100
