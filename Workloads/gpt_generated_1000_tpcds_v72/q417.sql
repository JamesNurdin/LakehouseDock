WITH
  inv_current AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2451081
  ),
  inv_past AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450843
  ),
  inv_extra AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450962
  ),
  promo_current AS (
    SELECT p_item_sk, p_cost, p_discount_active
    FROM promotion
    WHERE p_end_date_sk > 2450900
  ),
  promo_hist AS (
    SELECT p_item_sk, p_cost
    FROM promotion
    WHERE p_end_date_sk <= 2450900
  )
SELECT
  wh_stock.w_city AS warehouse_city,
  i.i_brand AS brand,
  COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
  SUM(sr.sr_return_amt) AS total_return_amount,
  SUM(inv_current.inv_quantity_on_hand) AS total_current_inventory,
  SUM(inv_past.inv_quantity_on_hand) AS total_past_inventory,
  SUM(inv_extra.inv_quantity_on_hand) AS total_extra_inventory,
  MIN(wh_extra.w_city) AS extra_warehouse_city,
  AVG(promo_current.p_cost) AS avg_current_promo_cost,
  AVG(promo_hist.p_cost) AS avg_hist_promo_cost
FROM item i
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN inv_current inv_current
  ON inv_current.inv_item_sk = i.i_item_sk
JOIN inv_past inv_past
  ON inv_past.inv_item_sk = i.i_item_sk
JOIN inv_extra inv_extra
  ON inv_extra.inv_item_sk = i.i_item_sk
JOIN warehouse wh_stock
  ON inv_current.inv_warehouse_sk = wh_stock.w_warehouse_sk
JOIN warehouse wh_ship
  ON inv_past.inv_warehouse_sk = wh_ship.w_warehouse_sk
JOIN warehouse wh_extra
  ON inv_extra.inv_warehouse_sk = wh_extra.w_warehouse_sk
JOIN promo_current promo_current
  ON promo_current.p_item_sk = i.i_item_sk
JOIN promo_hist promo_hist
  ON promo_hist.p_item_sk = i.i_item_sk
WHERE EXISTS (
        SELECT 1
        FROM promotion p_check
        WHERE p_check.p_item_sk = i.i_item_sk
          AND p_check.p_discount_active = 'Y'
      )
GROUP BY ROLLUP (wh_stock.w_city, i.i_brand)
ORDER BY warehouse_city, brand
LIMIT 100
