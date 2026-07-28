WITH inv_summary AS (
    SELECT i.i_item_sk,
           w.w_state AS warehouse_state,
           SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'                                   -- filter predicate 5
    GROUP BY i.i_item_sk, w.w_state
)
SELECT
    w.w_state AS warehouse_state,
    i.i_category,
    i.i_brand,
    ib.ib_income_band_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(COALESCE(invs.total_qty_on_hand, 0)) AS total_inventory_qty,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM catalog_sales cs
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_time_sk = t.t_time_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
 AND ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN inv_summary invs
  ON invs.i_item_sk = i.i_item_sk
 AND invs.warehouse_state = w.w_state
WHERE p.p_response_target = 1                                 -- filter predicate 1
  AND p.p_channel_details LIKE 'High%'                         -- filter predicate 2
  AND cr.cr_fee > 5                                            -- filter predicate 3
  AND ib.ib_lower_bound >= 50000                               -- filter predicate 4
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY w.w_state, i.i_category, i.i_brand, ib.ib_income_band_sk
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
