WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
sr_hd AS (
    SELECT sr.sr_ticket_number,
           hd.hd_income_band_sk,
           hd.hd_buy_potential
    FROM store_returns sr
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
),
ws_promo_full AS (
    SELECT ws.ws_order_number,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           p.p_promo_name,
           p.p_discount_active
    FROM sampled_ws ws
    FULL OUTER JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
),
order_common AS (
    SELECT ws_order_number AS order_key
    FROM ws_promo_full
    WHERE ws_order_number IS NOT NULL
    INTERSECT
    SELECT sr_ticket_number AS order_key
    FROM sr_hd
),
order_exclusive AS (
    SELECT ws_order_number AS order_key
    FROM sampled_ws
    EXCEPT
    SELECT sr_ticket_number AS order_key
    FROM sr_hd
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    wp.wp_type,
    hd.hd_buy_potential,
    RANK() OVER (PARTITION BY p.p_promo_name ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
    CASE
        WHEN ws.ws_ext_sales_price > 10000 THEN 'HIGH'
        WHEN ws.ws_ext_sales_price > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_category,
    EXISTS (SELECT 1 FROM sr_hd WHERE sr_hd.sr_ticket_number = ws.ws_order_number) AS is_returned
FROM sampled_ws ws
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    p.p_discount_active = 'Y'                     -- predicate 1
    AND sm.sm_type = 'AIR'                         -- predicate 2
    AND w.w_state = 'CA'                           -- predicate 3
    AND wp.wp_rec_start_date >= DATE '1999-01-01' -- predicate 4 (date column)
    AND wp.wp_max_ad_count BETWEEN 1 AND 3        -- predicate 5
    AND hd.hd_vehicle_count >= 2                  -- predicate 6
    AND ws.ws_quantity > 5                         -- predicate 7
ORDER BY ws.ws_ext_sales_price DESC
OFFSET 20 ROWS
LIMIT 100
