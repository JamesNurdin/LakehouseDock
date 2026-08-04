WITH
  ws_join AS (
    SELECT
      ws.ws_order_number               AS order_number,
      ws.ws_sold_date_sk               AS date_sk,
      ws.ws_item_sk                    AS item_sk,
      ws.ws_quantity                   AS quantity,
      ws.ws_ext_sales_price            AS amount,
      ws.ws_net_profit                 AS net_profit,
      td.t_hour                        AS hour,
      i.i_category                     AS category,
      i.i_brand                        AS brand,
      hd.hd_income_band_sk             AS income_band_sk,
      ib.ib_lower_bound                AS lower_bound,
      ib.ib_upper_bound                AS upper_bound,
      sm.sm_type                       AS ship_type,
      p.p_promo_name                   AS promo_name,
      p.p_discount_active              AS discount_active
    FROM web_sales ws
    JOIN time_dim td            ON ws.ws_sold_time_sk   = td.t_time_sk
    JOIN item i                 ON ws.ws_item_sk        = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm           ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN promotion p            ON ws.ws_promo_sk       = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450820
      AND i.i_manufact_id IN (169, 212)
      AND i.i_current_price > 5.00
      AND ib.ib_upper_bound <= 50000
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
  ),
  cr_join AS (
    SELECT
      cr.cr_order_number               AS order_number,
      cr.cr_returned_date_sk           AS date_sk,
      cr.cr_item_sk                    AS item_sk,
      cr.cr_return_quantity            AS quantity,
      cr.cr_return_amount              AS amount,
      cr.cr_net_loss                   AS net_profit,
      td.t_hour                        AS hour,
      i.i_category                     AS category,
      i.i_brand                        AS brand,
      hd.hd_income_band_sk             AS income_band_sk,
      ib.ib_lower_bound                AS lower_bound,
      ib.ib_upper_bound                AS upper_bound,
      sm.sm_type                       AS ship_type,
      p.p_promo_name                   AS promo_name,
      p.p_discount_active              AS discount_active
    FROM catalog_returns cr
    JOIN time_dim td            ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i                 ON cr.cr_item_sk          = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib         ON hd.hd_income_band_sk   = ib.ib_income_band_sk
    JOIN ship_mode sm           ON cr.cr_ship_mode_sk     = sm.sm_ship_mode_sk
    JOIN promotion p            ON p.p_item_sk            = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2450820
      AND i.i_manufact_id = 350
      AND cr.cr_return_amount > 20.00
      AND ib.ib_lower_bound >= 20000
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
  ),
  union_set AS (
    SELECT order_number, date_sk, item_sk, quantity, amount, net_profit,
           hour, category, brand, income_band_sk, lower_bound, upper_bound,
           ship_type, promo_name, discount_active
    FROM ws_join
    UNION DISTINCT
    SELECT order_number, date_sk, item_sk, quantity, amount, net_profit,
           hour, category, brand, income_band_sk, lower_bound, upper_bound,
           ship_type, promo_name, discount_active
    FROM cr_join
  ),
  intersect_set AS (
    SELECT order_number FROM ws_join
    INTERSECT
    SELECT order_number FROM cr_join
  )
SELECT
  hour,
  category,
  brand,
  ship_type,
  promo_name,
  SUM(total_amount)          AS sum_amount,
  AVG(total_amount)          AS avg_amount,
  COUNT(DISTINCT order_number) AS cnt_orders,
  MIN(total_amount)          AS min_amount,
  MAX(total_amount)          AS max_amount
FROM (
  SELECT
    u.order_number,
    u.amount AS total_amount,
    u.hour,
    u.category,
    u.brand,
    u.ship_type,
    u.promo_name
  FROM union_set u
  WHERE u.order_number IN (SELECT order_number FROM intersect_set)
) t
GROUP BY CUBE (hour, category, brand, ship_type, promo_name)
ORDER BY hour, category, brand, ship_type, promo_name
