/*
Goal: Analyze web sales performance by year, state and promotion, applying multiple filters, ranking, case classification, anti‑join, and combining results via UNION, INTERSECT and a FULL OUTER JOIN. The query joins all nine selected TPC‑DS tables using only the permitted join keys, aggregates key metrics, orders by total sales and limits to the top 100 rows.
*/
WITH
  /* Union of two filtered sales sets (distinct) */
  union_sales AS (
    SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_date_sk,
      ws_item_sk,
      ws_bill_cdemo_sk,
      ws_ship_cdemo_sk,
      ws_web_page_sk,
      ws_promo_sk,
      ws_order_number,
      ws_quantity,
      ws_net_paid_inc_ship_tax,
      ws_coupon_amt,
      ws_ext_discount_amt
    FROM web_sales
    WHERE ws_net_paid_inc_ship_tax > 1000.00
    UNION
    SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_date_sk,
      ws_item_sk,
      ws_bill_cdemo_sk,
      ws_ship_cdemo_sk,
      ws_web_page_sk,
      ws_promo_sk,
      ws_order_number,
      ws_quantity,
      ws_net_paid_inc_ship_tax,
      ws_coupon_amt,
      ws_ext_discount_amt
    FROM web_sales
    WHERE ws_quantity > 5
  ),
  /* Ranking within each promotion */
  ranked_union AS (
    SELECT
      us.*,
      ROW_NUMBER() OVER (PARTITION BY us.ws_promo_sk ORDER BY us.ws_net_paid_inc_ship_tax DESC) AS promo_rank
    FROM union_sales us
  ),
  /* Keep only top‑5 rows per promotion */
  filtered_union AS (
    SELECT *
    FROM ranked_union
    WHERE promo_rank <= 5
  ),
  /* Orders that appear both in sales (quantity >10) and have a return */
  intersect_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 10
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),
  /* Full outer join between store and inventory to keep unmatched rows */
  full_store_inventory AS (
    SELECT
      s.s_store_sk,
      s.s_state,
      i.inv_item_sk,
      i.inv_quantity_on_hand
    FROM store s
    FULL OUTER JOIN inventory i
      ON s.s_closed_date_sk = i.inv_date_sk
  )
SELECT
  d.d_year,
  s.s_state,
  p.p_promo_name,
  COUNT(DISTINCT fu.ws_order_number) AS order_cnt,
  SUM(fu.ws_net_paid_inc_ship_tax) AS total_sales,
  AVG(fu.ws_coupon_amt) AS avg_coupon,
  MIN(fu.ws_ext_discount_amt) AS min_discount,
  CASE WHEN SUM(fu.ws_quantity) > 1000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_volume_category
FROM filtered_union fu
JOIN date_dim d
  ON fu.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON fu.ws_sold_time_sk = t.t_time_sk
JOIN promotion p
  ON fu.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON fu.ws_web_page_sk = wp.wp_web_page_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON fu.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_returns wr
  ON wr.wr_order_number = fu.ws_order_number
JOIN intersect_orders io
  ON fu.ws_order_number = io.ws_order_number
LEFT JOIN full_store_inventory fsi
  ON fsi.s_store_sk = s.s_store_sk
  AND fsi.inv_item_sk = fu.ws_item_sk
WHERE
  d.d_year = 2001
  AND t.t_hour BETWEEN 9 AND 17
  AND p.p_channel_tv = 'N'
  AND s.s_state = 'CA'
  AND i.inv_quantity_on_hand > 500
  AND cd.cd_gender = 'M'
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = fu.ws_order_number
          AND wr2.wr_return_quantity > 0
      )
GROUP BY d.d_year, s.s_state, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
