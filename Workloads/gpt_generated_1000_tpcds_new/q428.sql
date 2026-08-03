WITH
  inv_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  store_full AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_item_sk,
      ss.ss_cdemo_sk,
      ss.ss_hdemo_sk,
      ss.ss_promo_sk,
      ss.ss_net_paid,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_return_tax
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
  ),
  catalog_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_promo_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cd.cd_credit_rating,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      p.p_promo_name,
      cp.cp_department,
      sm.sm_type,
      cc.cc_state
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cc.cc_state = 'CA'
  )
SELECT
  w.w_state,
  w.w_city,
  cj.p_promo_name,
  COUNT(DISTINCT cj.cs_order_number) AS distinct_orders,
  SUM(cj.cs_net_paid) AS total_net_paid,
  AVG(cj.cs_net_profit) AS avg_net_profit,
  inv_stats.avg_qty AS avg_inventory_qty,
  (SELECT COUNT(*) FROM promotion) AS total_promotions
FROM inv_sample i
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN LATERAL (
  SELECT avg(qty) AS avg_qty
  FROM (
    SELECT DISTINCT inv_quantity_on_hand AS qty
    FROM inventory
    WHERE inv_warehouse_sk = w.w_warehouse_sk
  ) d
) AS inv_stats ON TRUE
JOIN catalog_join cj
  ON cj.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_full sf
  ON sf.ss_item_sk = cj.cs_item_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cj.cs_order_number
      )
  AND w.w_state = 'WA'
  AND i.inv_quantity_on_hand > 100
GROUP BY
  w.w_state,
  w.w_city,
  cj.p_promo_name,
  inv_stats.avg_qty
ORDER BY total_net_paid DESC
LIMIT 100
