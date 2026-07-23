WITH store_agg AS (
   SELECT
      d.d_year AS year,
      p.p_promo_id,
      p.p_promo_name,
      SUM(ss.ss_net_profit) AS store_net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 1998
     AND s.s_state = 'CA'
     AND ss.ss_net_profit > 0
     AND p.p_discount_active = 'Y'
   GROUP BY d.d_year, p.p_promo_id, p.p_promo_name
),
catalog_agg AS (
   SELECT
      d.d_year AS year,
      p.p_promo_id,
      p.p_promo_name,
      SUM(cs.cs_net_profit) AS catalog_net_profit,
      SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   WHERE d.d_year = 1998
     AND cs.cs_quantity > 5
   GROUP BY d.d_year, p.p_promo_id, p.p_promo_name
),
web_agg AS (
   SELECT
      d.d_year AS year,
      p.p_promo_id,
      p.p_promo_name,
      SUM(ws.ws_net_profit) AS web_net_profit,
      SUM(ws.ws_coupon_amt) AS total_coupon_amount
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   WHERE d.d_year = 1998
     AND ws.ws_coupon_amt > 100
   GROUP BY d.d_year, p.p_promo_id, p.p_promo_name
),
returns_agg AS (
   SELECT
      d.d_year AS year,
      p.p_promo_id,
      p.p_promo_name,
      SUM(cr.cr_net_loss) AS returns_net_loss,
      COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
   FROM catalog_returns cr
   JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, p.p_promo_id, p.p_promo_name
)
SELECT
   sa.year,
   sa.p_promo_id,
   sa.p_promo_name,
   sa.store_net_profit,
   ca.catalog_net_profit,
   wa.web_net_profit,
   ra.returns_net_loss,
   (sa.store_net_profit + ca.catalog_net_profit + wa.web_net_profit - ra.returns_net_loss) AS total_net_profit,
   (sa.store_net_profit + ca.catalog_net_profit + wa.web_net_profit - ra.returns_net_loss) / NULLIF((sa.store_net_profit + ca.catalog_net_profit + wa.web_net_profit), 0) AS profit_margin,
   ra.distinct_return_orders
FROM store_agg sa
JOIN catalog_agg ca ON sa.year = ca.year AND sa.p_promo_id = ca.p_promo_id
JOIN web_agg wa ON sa.year = wa.year AND sa.p_promo_id = wa.p_promo_id
JOIN returns_agg ra ON sa.year = ra.year AND sa.p_promo_id = ra.p_promo_id
WHERE (sa.store_net_profit + ca.catalog_net_profit + wa.web_net_profit - ra.returns_net_loss) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
