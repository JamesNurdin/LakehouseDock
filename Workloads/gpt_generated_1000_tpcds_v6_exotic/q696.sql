WITH
  cat_base AS (
    SELECT
      p.p_promo_id,
      p.p_promo_name,
      cs.cs_net_paid,
      cs.cs_sales_price,
      cc.cc_state,
      cd.cd_purchase_estimate,
      hd.hd_buy_potential,
      ib.ib_upper_bound,
      sm.sm_carrier,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN promotion p            ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm           ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w            ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv          ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss         ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s                ON ss.ss_store_sk = s.s_store_sk
    WHERE
      cc.cc_state = 'CA'
      AND cd.cd_purchase_estimate > 2000
      AND hd.hd_buy_potential = '1001-5000'
      AND ib.ib_upper_bound <= 60000
      AND p.p_discount_active = 'Y'
      AND sm.sm_carrier = 'UPS'
      AND cs.cs_sales_price > 50
  ),
  web_base AS (
    SELECT
      p.p_promo_id,
      p.p_promo_name,
      ws.ws_net_paid,
      ws.ws_sales_price,
      ws.ws_net_profit,
      we.web_state,
      cd.cd_purchase_estimate,
      hd.hd_buy_potential,
      ib.ib_upper_bound,
      sm.sm_carrier,
      inv.inv_quantity_on_hand,
      wr.wr_net_loss,
      r.r_reason_desc
    FROM web_sales ws
    JOIN promotion p            ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w            ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv          ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we            ON ws.ws_web_site_sk = we.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr   ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r         ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
      we.web_state = 'CA'
      AND cd.cd_purchase_estimate > 1500
      AND hd.hd_buy_potential = '501-1000'
      AND ib.ib_upper_bound <= 50000
      AND p.p_discount_active = 'Y'
      AND sm.sm_carrier = 'UPS'
      AND ws.ws_net_profit > 0
  )
SELECT
  promo_id,
  promo_name,
  source,
  total_amount,
  RANK() OVER (ORDER BY total_amount DESC) AS amount_rank
FROM (
  SELECT
    p_promo_id   AS promo_id,
    p_promo_name AS promo_name,
    'Catalog'    AS source,
    SUM(cs_net_paid) AS total_amount
  FROM cat_base
  GROUP BY p_promo_id, p_promo_name

  UNION ALL

  SELECT
    p_promo_id   AS promo_id,
    p_promo_name AS promo_name,
    'Web'        AS source,
    SUM(ws_net_paid) AS total_amount
  FROM web_base
  GROUP BY p_promo_id, p_promo_name
) t
ORDER BY total_amount DESC, source
LIMIT 100
