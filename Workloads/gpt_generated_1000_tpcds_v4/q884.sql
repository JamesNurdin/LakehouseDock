WITH base AS (
  SELECT
    d.d_year,
    hd.hd_buy_potential,
    CASE WHEN hd.hd_vehicle_count > 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS vehicle_category,
    p.p_promo_name,
    sm.sm_type,
    cp.cp_department,
    ib.ib_lower_bound,
    cs.cs_net_paid_inc_tax,
    ss.ss_net_paid_inc_tax,
    ws.ws_net_paid_inc_tax
  FROM
    tpcds.date_dim d
    JOIN tpcds.store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
         AND cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk = cs.cs_item_sk
         AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
         AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
         AND sr.sr_item_sk = ss.ss_item_sk
         AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.inventory inv
      ON inv.inv_date_sk = d.d_date_sk
  WHERE
    d.d_year = 2001
    AND hd.hd_dep_count >= 2
    AND p.p_discount_active = 'Y'
    AND cp.cp_department = 'Books'
    AND sm.sm_type = 'AIR'
    AND we.web_state = 'CA'
    AND inv.inv_quantity_on_hand > 0
),
agg AS (
  SELECT
    d_year,
    hd_buy_potential,
    vehicle_category,
    p_promo_name,
    sm_type,
    cp_department,
    ib_lower_bound,
    SUM(COALESCE(cs_net_paid_inc_tax, 0) + COALESCE(ss_net_paid_inc_tax, 0) + COALESCE(ws_net_paid_inc_tax, 0)) AS total_net_paid
  FROM base
  GROUP BY
    d_year,
    hd_buy_potential,
    vehicle_category,
    p_promo_name,
    sm_type,
    cp_department,
    ib_lower_bound
)
SELECT
  d_year,
  AVG(total_net_paid) AS avg_total_net_paid
FROM agg
GROUP BY d_year
ORDER BY avg_total_net_paid DESC
LIMIT 100
