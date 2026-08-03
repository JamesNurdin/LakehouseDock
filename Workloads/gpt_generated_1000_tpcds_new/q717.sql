WITH
  union_sales AS (
    /* Promotional sales with high‑priced items */
    SELECT
      ws.ws_item_sk,
      i.i_product_name,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      CASE WHEN SUM(ws.ws_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'FullPrice' END AS discount_flag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_current_price > 100
    GROUP BY ws.ws_item_sk, i.i_product_name
    UNION DISTINCT
    /* Non‑promotional sales shipped by AIR mode */
    SELECT
      ws.ws_item_sk,
      i.i_product_name,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      CASE WHEN SUM(ws.ws_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'FullPrice' END AS discount_flag
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_promo_sk IS NULL
      AND ws.ws_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR'
      )
    GROUP BY ws.ws_item_sk, i.i_product_name
  ),
  customer_sales AS (
    SELECT
      ws.ws_item_sk,
      i.i_product_name,
      SUM(ws.ws_ext_sales_price) AS cust_total_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
    GROUP BY ws.ws_item_sk, i.i_product_name
  ),
  intersect_keys AS (
    SELECT us.ws_item_sk, us.i_product_name
    FROM union_sales us
    INTERSECT
    SELECT cs.ws_item_sk, cs.i_product_name
    FROM customer_sales cs
  )
SELECT
  us.ws_item_sk,
  us.i_product_name,
  us.total_sales,
  us.discount_flag,
  (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2) AS avg_net_paid
FROM union_sales us
JOIN intersect_keys ik
  ON us.ws_item_sk = ik.ws_item_sk
 AND us.i_product_name = ik.i_product_name
WHERE us.ws_item_sk IN (
  SELECT i_item_sk FROM item WHERE i_brand = 'Brand#12'
)
ORDER BY us.total_sales DESC
LIMIT 100
