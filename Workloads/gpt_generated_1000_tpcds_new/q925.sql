WITH
  sales_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_promo_sk,
      ss.ss_sold_time_sk,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
  ),
  item_dim AS (
    SELECT i_item_sk, i_category, i_brand, i_color, i_current_price
    FROM item
    WHERE i_current_price > 10
  ),
  cust_dim AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
  ),
  promo_dim AS (
    SELECT p_promo_sk, p_discount_active, p_promo_name
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),
  time_dim_f AS (
    SELECT t_time_sk, t_am_pm, t_hour, t_meal_time
    FROM time_dim
    WHERE t_am_pm = 'PM' AND t_hour BETWEEN 12 AND 17
  ),
  hd_dim AS (
    SELECT hd_demo_sk, hd_buy_potential, hd_income_band_sk
    FROM household_demographics
    WHERE hd_buy_potential = '5000-9999'
  ),
  income_dim AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 50000
  ),
  inventory_dim AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
  ),
  web_page_dim AS (
    SELECT wp_web_page_sk, wp_customer_sk, wp_image_count, wp_url
    FROM web_page
    WHERE wp_image_count >= 3
  ),
  reason_dim AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%defect%'
  ),
  web_return_sub AS (
    SELECT wr_item_sk, wr_return_quantity, wr_return_amt, wr_reason_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
  )
SELECT
  c.c_first_name,
  c.c_last_name,
  i.i_category,
  p.p_promo_name,
  t.t_meal_time,
  COUNT(DISTINCT s.ss_ticket_number) AS distinct_tickets,
  SUM(s.ss_quantity) AS total_quantity,
  SUM(s.ss_ext_sales_price) AS total_sales,
  AVG(CASE WHEN i.i_color = 'Red' THEN s.ss_ext_sales_price ELSE NULL END) AS avg_red_item_sales,
  SUM(CASE WHEN r.r_reason_desc IS NOT NULL THEN wr.wr_return_amt ELSE 0 END) AS total_return_amount,
  MIN(s.ss_net_paid) AS min_net_paid,
  MAX(s.ss_net_profit) AS max_net_profit
FROM sales_base s
JOIN item_dim i        ON s.ss_item_sk = i.i_item_sk
JOIN cust_dim c        ON s.ss_customer_sk = c.c_customer_sk
JOIN promo_dim p       ON s.ss_promo_sk = p.p_promo_sk
JOIN time_dim_f t      ON s.ss_sold_time_sk = t.t_time_sk
JOIN hd_dim hd         ON s.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_dim inc    ON hd.hd_income_band_sk = inc.ib_income_band_sk
JOIN inventory_dim inv ON i.i_item_sk = inv.inv_item_sk
JOIN web_page_dim wp   ON c.c_customer_sk = wp.wp_customer_sk
JOIN web_return_sub wr ON i.i_item_sk = wr.wr_item_sk
JOIN reason_dim r      ON wr.wr_reason_sk = r.r_reason_sk
WHERE i.i_brand = 'Brand#12'
  AND p.p_promo_name LIKE '%Summer%'
  AND t.t_meal_time = 'dinner'
  AND inc.ib_upper_bound <= 100000
GROUP BY
  c.c_first_name,
  c.c_last_name,
  i.i_category,
  p.p_promo_name,
  t.t_meal_time
HAVING COUNT(*) > 10
INTERSECT
SELECT
  c2.c_first_name,
  c2.c_last_name,
  i2.i_category,
  p2.p_promo_name,
  t2.t_meal_time,
  COUNT(DISTINCT s2.ss_ticket_number),
  SUM(s2.ss_quantity),
  SUM(s2.ss_ext_sales_price),
  AVG(CASE WHEN i2.i_color = 'Red' THEN s2.ss_ext_sales_price ELSE NULL END),
  SUM(CASE WHEN r2.r_reason_desc IS NOT NULL THEN wr2.wr_return_amt ELSE 0 END),
  MIN(s2.ss_net_paid),
  MAX(s2.ss_net_profit)
FROM sales_base s2
JOIN item_dim i2        ON s2.ss_item_sk = i2.i_item_sk
JOIN cust_dim c2        ON s2.ss_customer_sk = c2.c_customer_sk
JOIN promo_dim p2       ON s2.ss_promo_sk = p2.p_promo_sk
JOIN time_dim_f t2      ON s2.ss_sold_time_sk = t2.t_time_sk
JOIN hd_dim hd2         ON s2.ss_hdemo_sk = hd2.hd_demo_sk
JOIN income_dim inc2    ON hd2.hd_income_band_sk = inc2.ib_income_band_sk
JOIN inventory_dim inv2 ON i2.i_item_sk = inv2.inv_item_sk
JOIN web_page_dim wp2   ON c2.c_customer_sk = wp2.wp_customer_sk
JOIN web_return_sub wr2 ON i2.i_item_sk = wr2.wr_item_sk
JOIN reason_dim r2      ON wr2.wr_reason_sk = r2.r_reason_sk
WHERE i2.i_brand = 'Brand#12'
  AND p2.p_promo_name LIKE '%Summer%'
  AND t2.t_meal_time = 'dinner'
  AND inc2.ib_upper_bound <= 100000
GROUP BY
  c2.c_first_name,
  c2.c_last_name,
  i2.i_category,
  p2.p_promo_name,
  t2.t_meal_time
HAVING COUNT(*) > 10
LIMIT 100
