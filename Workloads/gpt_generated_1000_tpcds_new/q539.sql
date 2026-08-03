WITH
  sales_data AS (
    SELECT
      ss.ss_sold_date_sk AS date_sk,
      i.i_category AS category,
      c.c_customer_id AS customer_id,
      ca.ca_state AS state,
      ss.ss_quantity AS quantity,
      ss.ss_ext_sales_price AS sales_amount,
      ss.ss_net_profit AS net_profit,
      CASE WHEN ss.ss_coupon_amt > 0 THEN 'Coupon' ELSE 'NoCoupon' END AS coupon_flag
    FROM store_sales ss
      JOIN item i ON ss.ss_item_sk = i.i_item_sk
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND ss.ss_item_sk IN (SELECT i_item_sk FROM item WHERE i_color = 'Red')
      AND inv.inv_quantity_on_hand > 0
  ),
  returns_data AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      i.i_category AS category,
      c.c_customer_id AS customer_id,
      ca.ca_state AS state,
      cr.cr_return_quantity AS quantity,
      -cr.cr_return_amount AS sales_amount,
      -cr.cr_net_loss AS net_profit,
      'NoCoupon' AS coupon_flag
    FROM catalog_returns cr
      JOIN item i ON cr.cr_item_sk = i.i_item_sk
      JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND i.i_brand = 'Brand#12'

    UNION DISTINCT

    SELECT
      wr.wr_returned_date_sk AS date_sk,
      i.i_category AS category,
      c.c_customer_id AS customer_id,
      ca.ca_state AS state,
      wr.wr_return_quantity AS quantity,
      -wr.wr_return_amt AS sales_amount,
      -wr.wr_net_loss AS net_profit,
      'NoCoupon' AS coupon_flag
    FROM web_returns wr
      JOIN item i ON wr.wr_item_sk = i.i_item_sk
      JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
      JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
      JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND i.i_brand = 'Brand#12'
  ),
  combined AS (
    SELECT * FROM sales_data
    UNION DISTINCT
    SELECT * FROM returns_data
  )
SELECT
  COALESCE(category, 'ALL') AS category,
  COALESCE(state, 'ALL') AS state,
  SUM(quantity) AS total_quantity,
  SUM(sales_amount) AS total_sales,
  AVG(net_profit) AS avg_net_profit,
  COUNT(DISTINCT customer_id) AS distinct_customers,
  SUM(CASE WHEN coupon_flag = 'Coupon' THEN 1 ELSE 0 END) AS coupon_transactions
FROM combined
GROUP BY ROLLUP (category, state)
ORDER BY category, state
LIMIT 100
