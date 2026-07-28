WITH catalog_agg AS (
   SELECT
       i.i_category AS category,
       CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS shipping_type,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(*) AS order_cnt
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
   JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE
       sm.sm_contract IN ('GNJr3g5i7oorKqtX','Ek')
       AND p.p_channel_email = 'N'
       AND cd_bill.cd_education_status = 'Advanced Degree'
       AND hd_bill.hd_vehicle_count > 1
       AND inv.inv_quantity_on_hand > 0
       AND i.i_current_price > 20
       AND ib.ib_lower_bound >= 20000
       AND i.i_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
   GROUP BY
       i.i_category,
       CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END
),
web_agg AS (
   SELECT
       i.i_category AS category,
       CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END AS shipping_type,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(*) AS order_cnt
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
   JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
   JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE
       sm.sm_contract IN ('GNJr3g5i7oorKqtX','Ek')
       AND p.p_channel_email = 'N'
       AND cd_bill.cd_education_status = 'Advanced Degree'
       AND hd_bill.hd_vehicle_count > 1
       AND inv.inv_quantity_on_hand > 0
       AND i.i_current_price > 20
       AND ib.ib_lower_bound >= 20000
       AND wp.wp_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
   GROUP BY
       i.i_category,
       CASE WHEN sm.sm_code = 'AIR' THEN 'Air' ELSE 'Other' END
),
combined AS (
   SELECT category, shipping_type, total_net_paid, order_cnt FROM catalog_agg
   UNION ALL
   SELECT category, shipping_type, total_net_paid, order_cnt FROM web_agg
),
final AS (
   SELECT
       category,
       shipping_type,
       SUM(total_net_paid) AS sum_net_paid,
       AVG(total_net_paid) AS avg_net_paid,
       SUM(order_cnt) AS total_orders,
       COUNT(*) AS num_groups
   FROM combined
   GROUP BY category, shipping_type
   HAVING SUM(total_net_paid) > 10000
)
SELECT
   category,
   shipping_type,
   sum_net_paid,
   avg_net_paid,
   total_orders
FROM final
ORDER BY sum_net_paid DESC
LIMIT 100
