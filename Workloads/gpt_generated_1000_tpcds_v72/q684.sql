WITH store_sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
      AND ss.ss_net_paid > 0
      AND ss.ss_sold_date_sk BETWEEN 2451910 AND 2451920
    GROUP BY ss.ss_item_sk, ss.ss_hdemo_sk, ss.ss_addr_sk, ss.ss_ticket_number
)
SELECT
    ca.ca_state,
    i.i_brand,
    CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Regular' END AS price_category,
    SUM(ssa.store_net_paid)               AS total_store_paid,
    SUM(ws.ws_net_paid)                    AS total_web_paid,
    SUM(cs.cs_net_paid)                    AS total_catalog_paid,
    SUM(inv.inv_quantity_on_hand)          AS total_inventory,
    SUM(ib.ib_upper_bound)                 AS total_income_upper
FROM store_sales_agg ssa
JOIN item i
  ON ssa.ss_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON ssa.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON ssa.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ssa.ss_item_sk
  AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
  AND cr.cr_order_number = cs.cs_order_number
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY')
  AND i.i_brand IN ('Brand#12', 'Brand#23')
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound < 100000
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
GROUP BY
    ca.ca_state,
    i.i_brand,
    CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Regular' END
HAVING SUM(ssa.store_net_paid) > 5000
ORDER BY total_store_paid DESC
LIMIT 100
