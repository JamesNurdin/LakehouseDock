WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      max(inv_quantity_on_hand) AS max_qty
    FROM inventory
    GROUP BY inv_item_sk
  ),
  sales AS (
    SELECT
      ss_sold_date_sk,
      ss_store_sk,
      ss_customer_sk,
      ss_item_sk,
      ss_ticket_number,
      ss_net_paid,
      ss_quantity,
      CASE WHEN ss_net_paid > 1000 THEN 'High' ELSE 'Low' END AS payment_category
    FROM store_sales
    WHERE ss_quantity BETWEEN 30 AND 100
      AND ss_net_paid IS NOT NULL
  ),
  joined AS (
    SELECT
      d.d_year,
      s.s_store_name,
      c.c_first_name,
      c.c_last_name,
      sa.payment_category,
      sa.ss_net_paid,
      sa.ss_quantity,
      i.max_qty,
      sr.sr_return_quantity,
      wp.wp_web_page_sk
    FROM sales sa
    JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
    JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = sa.ss_ticket_number
      AND sr.sr_item_sk = sa.ss_item_sk
      AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN inv_agg i ON i.inv_item_sk = sa.ss_item_sk
    LEFT JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
      AND wp.wp_type = 'promo'
    WHERE d.d_year IN (1999, 2000, 2001)
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND (i.max_qty IS NULL OR i.max_qty > 0)
      AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity < 5)
      AND wp.wp_type = 'promo'
  )
SELECT
  d_year,
  s_store_name,
  c_first_name,
  c_last_name,
  payment_category,
  SUM(ss_net_paid) AS total_net_paid,
  SUM(ss_quantity) AS total_quantity,
  MAX(max_qty) AS max_inventory_qty,
  SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
  COUNT(DISTINCT wp_web_page_sk) AS promo_page_count,
  RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM joined
GROUP BY d_year, s_store_name, c_first_name, c_last_name, payment_category
ORDER BY d_year, sales_rank
