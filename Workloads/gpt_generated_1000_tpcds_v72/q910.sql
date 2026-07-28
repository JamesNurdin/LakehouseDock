WITH
  store_part AS (
    SELECT
      d.d_date AS sale_date,
      'store' AS channel,
      i.i_item_id,
      i.i_product_name,
      ss.ss_net_profit AS net_profit,
      (
        SELECT avg(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
      ) AS avg_year_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ss.ss_net_profit > 1000
      AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_discount_active = 'Y'
      )
  ),
  web_part AS (
    SELECT
      d.d_date AS sale_date,
      'web' AS channel,
      i.i_item_id,
      i.i_product_name,
      ws.ws_net_profit AS net_profit,
      (
        SELECT avg(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
      ) AS avg_year_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ws.ws_net_profit > 1000
  )
SELECT
  sale_date,
  channel,
  i_item_id,
  i_product_name,
  net_profit,
  avg_year_profit
FROM store_part
UNION ALL
SELECT
  sale_date,
  channel,
  i_item_id,
  i_product_name,
  net_profit,
  avg_year_profit
FROM web_part
ORDER BY sale_date DESC, net_profit DESC
LIMIT 100
