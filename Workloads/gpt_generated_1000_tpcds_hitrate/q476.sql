WITH filtered_item AS (
       SELECT i_item_sk,
              i_category_id,
              i_manager_id,
              i_current_price
       FROM   item
       WHERE  i_category_id IN (1, 2, 3)
         AND  i_manager_id IN (41, 44)
   ),
   promo AS (
       SELECT p_promo_sk,
              p_item_sk,
              p_discount_active,
              p_cost
       FROM   promotion
       WHERE  p_discount_active = 'Y'
   ),
   income_bounds AS (
       SELECT ib_income_band_sk,
              ib_lower_bound,
              ib_upper_bound
       FROM   income_band
       WHERE  ib_lower_bound >= 40000
   )
SELECT
       c.c_customer_id,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       i.i_category_id,
       SUM(wr.wr_return_amt)                         AS total_return_amount,
       AVG(i.i_current_price)                        AS avg_item_price,
       COUNT(DISTINCT wr.wr_order_number)            AS distinct_orders,
       CASE WHEN SUM(wr.wr_return_amt) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_severity,
       grp.flag
FROM   web_returns wr
JOIN   filtered_item i
       ON wr.wr_item_sk = i.i_item_sk
JOIN   promo p
       ON p.p_item_sk = i.i_item_sk
JOIN   customer c
       ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN   household_demographics hd
       ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN   income_bounds ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN   web_page wp
       ON wr.wr_web_page_sk = wp.wp_web_page_sk
CROSS JOIN (SELECT 1 AS flag UNION ALL SELECT 2 AS flag) AS grp
WHERE  c.c_birth_month = 5
  AND  c.c_salutation = 'Mr.'
  AND  wp.wp_type = 'Content'
  AND  ib.ib_upper_bound <= 100000
  AND  EXISTS (
          SELECT 1
          FROM   promotion p2
          WHERE  p2.p_item_sk = i.i_item_sk
            AND  p2.p_cost < 500
       )
GROUP BY
       c.c_customer_id,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       i.i_category_id,
       grp.flag
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
