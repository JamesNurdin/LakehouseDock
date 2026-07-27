WITH
  store_agg AS (
    SELECT
      'Store' AS source_type,
      s.s_store_id AS location_id,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > 1
      AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_discount_active = 'Y'
      )
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_ext_sales_price) > 10000
  ),
  web_agg AS (
    SELECT
      'Web' AS source_type,
      w.web_name AS location_id,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS txn_count
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE t.t_shift = 'Evening'
      AND ws.ws_quantity > 2
      AND (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_brand = 'Brand#12'
      ) < ws.ws_sales_price
    GROUP BY w.web_name
    HAVING SUM(ws.ws_ext_sales_price) > 15000
  )
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
