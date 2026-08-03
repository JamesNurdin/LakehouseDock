WITH
  base1 AS (
    SELECT
      wp.wp_type,
      ws.ws_promo_sk,
      ws.ws_order_number,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_link_count > 5
      AND ws.ws_wholesale_cost < 50
    GROUP BY CUBE (wp.wp_type, ws.ws_promo_sk, ws.ws_order_number)
    HAVING ws.ws_order_number IS NOT NULL
  ),
  base2 AS (
    SELECT
      wp.wp_type,
      ws.ws_promo_sk,
      ws.ws_order_number,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_char_count BETWEEN 1000 AND 6000
      AND ws.ws_coupon_amt < 200
    GROUP BY CUBE (wp.wp_type, ws.ws_promo_sk, ws.ws_order_number)
    HAVING ws.ws_order_number IS NOT NULL
  ),
  combined AS (
    SELECT * FROM base1
    UNION ALL
    SELECT * FROM base2
  ),
  ranked AS (
    SELECT
      wp_type,
      ws_promo_sk,
      ws_order_number,
      total_sales,
      total_profit,
      cnt,
      ROW_NUMBER() OVER (PARTITION BY wp_type, ws_promo_sk ORDER BY total_profit DESC) AS rk
    FROM combined
    WHERE ws_order_number NOT IN (
      SELECT ws.ws_order_number FROM tpcds.web_sales ws WHERE ws.ws_coupon_amt > 500
    )
  )
SELECT
  wp_type,
  ws_promo_sk,
  ws_order_number,
  total_sales,
  total_profit,
  cnt
FROM ranked
WHERE rk <= 5
ORDER BY wp_type, ws_promo_sk, total_profit DESC
LIMIT 100
