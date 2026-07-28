WITH
  cs AS (
    SELECT
      cs.cs_item_sk,
      SUM(cs.cs_net_paid)               AS cs_net_paid,
      SUM(cs.cs_quantity)               AS cs_qty,
      cs.cs_bill_hdemo_sk                AS hd_demo_sk,
      ca.ca_state,
      hd.hd_income_band_sk,
      sm.sm_carrier,
      p.p_promo_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2451200
      AND cs.cs_ext_discount_amt > 0
      AND i.i_units = 'Box'
    GROUP BY
      cs.cs_item_sk,
      cs.cs_bill_hdemo_sk,
      ca.ca_state,
      hd.hd_income_band_sk,
      sm.sm_carrier,
      p.p_promo_name
  ),
  cr AS (
    SELECT
      cr.cr_item_sk,
      SUM(cr.cr_return_amount) AS cr_ret_amt,
      COUNT(*)                AS cr_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2451200
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_item_sk
  ),
  ss AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_net_paid) AS ss_net_paid,
      SUM(ss.ss_quantity) AS ss_qty,
      st.s_state,
      pm.p_promo_name AS store_promo_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion pm ON ss.ss_promo_sk = pm.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2451200
      AND i.i_category = 'Electronics'
    GROUP BY
      ss.ss_item_sk,
      st.s_state,
      pm.p_promo_name
  ),
  sr AS (
    SELECT
      sr.sr_item_sk,
      SUM(sr.sr_return_amt) AS sr_ret_amt,
      COUNT(*)               AS sr_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450800 AND 2451200
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk
  ),
  inv AS (
    SELECT
      inv.inv_item_sk,
      SUM(inv.inv_quantity_on_hand) AS inv_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_date_sk = 2451100
    GROUP BY inv.inv_item_sk
  ),
  promo AS (
    SELECT
      p.p_item_sk,
      COUNT(*)                     AS promo_cnt,
      MIN(p.p_channel_email)       AS channel_email
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
    GROUP BY p.p_item_sk
  ),
  hd AS (
    SELECT
      hd_demo_sk,
      AVG(hd_income_band_sk) AS avg_income_band
    FROM household_demographics
    GROUP BY hd_demo_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  i.i_units,
  i.i_current_price,
  cs.cs_net_paid,
  ss.ss_net_paid,
  cr.cr_ret_amt,
  sr.sr_ret_amt,
  inv.inv_on_hand,
  promo.promo_cnt,
  hd.avg_income_band,
  RANK() OVER (ORDER BY (COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) DESC) AS sales_rank,
  CASE WHEN promo.promo_cnt > 5 THEN 'HighPromo' ELSE 'LowPromo' END AS promo_level
FROM item i
LEFT JOIN cs    ON i.i_item_sk = cs.cs_item_sk
LEFT JOIN ss    ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN cr    ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN sr    ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN inv   ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN promo ON i.i_item_sk = promo.p_item_sk
LEFT JOIN hd    ON cs.hd_demo_sk = hd.hd_demo_sk
WHERE i.i_units IN ('Box', 'Case')
  AND i.i_rec_end_date > DATE '2000-01-01'
  AND i.i_category = 'Electronics'
  AND i.i_brand = 'Brand#12'
ORDER BY sales_rank
LIMIT 100
