WITH
  -- Subquery A: store sales perspective
  store_sales_agg AS (
    SELECT
      d.d_year AS year,
      CASE WHEN ib.ib_upper_bound > 50000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
      sm.sm_ship_mode_id AS ship_mode_id,
      COUNT(DISTINCT ss.ss_ticket_number) AS orders,
      SUM(ss.ss_net_paid) AS net_paid,
      SUM(COALESCE(cr.cr_return_amount, 0)) AS return_amount,
      SUM(inv.inv_quantity_on_hand) AS inventory_qty,
      AVG(p.p_cost) AS avg_promo_cost,
      MIN(d.d_date) AS min_date,
      MAX(d.d_date) AS max_date
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON d.d_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 1998
      AND inv.inv_quantity_on_hand > 100
      AND p.p_discount_active = 'Y'
    GROUP BY
      d.d_year,
      CASE WHEN ib.ib_upper_bound > 50000 THEN 'High Income' ELSE 'Low Income' END,
      sm.sm_ship_mode_id
  ),

  -- Subquery B: web sales perspective
  web_sales_agg AS (
    SELECT
      d.d_year AS year,
      CASE WHEN ib.ib_upper_bound > 50000 THEN 'High Income' ELSE 'Low Income' END AS income_category,
      sm.sm_ship_mode_id AS ship_mode_id,
      COUNT(DISTINCT ws.ws_order_number) AS orders,
      SUM(ws.ws_net_paid) AS net_paid,
      SUM(COALESCE(cr.cr_return_amount, 0)) AS return_amount,
      SUM(inv.inv_quantity_on_hand) AS inventory_qty,
      AVG(p.p_cost) AS avg_promo_cost,
      MIN(d.d_date) AS min_date,
      MAX(d.d_date) AS max_date
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON d.d_date_sk = inv.inv_date_sk
    JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 1998
      AND ws_site.web_tax_percentage > 0.03
      AND inv.inv_quantity_on_hand > 100
      AND p.p_discount_active = 'Y'
    GROUP BY
      d.d_year,
      CASE WHEN ib.ib_upper_bound > 50000 THEN 'High Income' ELSE 'Low Income' END,
      sm.sm_ship_mode_id
  )

SELECT
  year,
  income_category,
  ship_mode_id,
  orders,
  net_paid,
  return_amount,
  inventory_qty,
  avg_promo_cost,
  min_date,
  max_date
FROM (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
) AS combined
ORDER BY net_paid DESC
LIMIT 100
