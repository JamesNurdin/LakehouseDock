WITH base AS (
  SELECT
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT wp.wp_web_page_id) AS unique_web_pages,
    COUNT(*) AS total_records
  FROM household_demographics hd
  JOIN inventory inv
    ON inv.inv_warehouse_sk = hd.hd_income_band_sk
  JOIN promotion p
    ON p.p_item_sk = inv.inv_item_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = p.p_start_date_sk
  WHERE hd.hd_income_band_sk IN (2, 3, 4, 5)
    AND inv.inv_quantity_on_hand > 200
    AND p.p_discount_active = 'Y'
    AND wp.wp_type = 'Landing'
  GROUP BY hd.hd_buy_potential, hd.hd_vehicle_count, hd.hd_dep_count
  HAVING COUNT(*) > 10
),
ranked AS (
  SELECT
    base.*, 
    ROW_NUMBER() OVER (PARTITION BY base.hd_buy_potential ORDER BY base.avg_qty_on_hand DESC) AS rn
  FROM base
)
SELECT
  hd_buy_potential,
  hd_vehicle_count,
  hd_dep_count,
  avg_qty_on_hand,
  total_promo_cost,
  unique_web_pages,
  total_records,
  rn AS rank_within_buy_potential
FROM ranked
WHERE rn <= 3
ORDER BY avg_qty_on_hand DESC
LIMIT 20
