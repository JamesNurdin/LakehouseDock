WITH
  store_agg AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      SUM(ss.ss_ext_sales_price) AS store_sales_total,
      COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY
      p.p_promo_sk,
      p.p_promo_name
  ),

  web_agg AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      ws.ws_web_site_sk,
      w.web_name,
      SUM(ws.ws_ext_sales_price) AS web_sales_total,
      COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
      regexp_like(w.web_name, '^A.*')               -- name starts with "A"
      AND w.web_name LIKE '%Store%'
    GROUP BY
      p.p_promo_sk,
      p.p_promo_name,
      ws.ws_web_site_sk,
      w.web_name
  )

SELECT
  COALESCE(s.p_promo_name, w.p_promo_name) AS promo_name,
  COALESCE(s.p_promo_sk, w.p_promo_sk) AS promo_sk,
  CONCAT('Promo_', CAST(COALESCE(s.p_promo_sk, w.p_promo_sk) AS VARCHAR)) AS promo_id,
  REGEXP_EXTRACT(COALESCE(s.p_promo_name, w.p_promo_name), '(.*) Discount', 1) AS discount_type,
  COALESCE(s.store_sales_total, 0) AS store_sales_total,
  COALESCE(s.store_txn_cnt, 0) AS store_txn_cnt,
  COALESCE(w.web_sales_total, 0) AS web_sales_total,
  COALESCE(w.web_txn_cnt, 0) AS web_txn_cnt,
  w.web_name
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.p_promo_sk = w.p_promo_sk
WHERE EXISTS (
  SELECT 1
  FROM web_returns wr
  JOIN web_sales ws2
    ON wr.wr_order_number = ws2.ws_order_number
  WHERE ws2.ws_promo_sk = COALESCE(s.p_promo_sk, w.p_promo_sk)
)
  AND (COALESCE(s.p_promo_name, w.p_promo_name) LIKE '%Summer%')
  AND REGEXP_LIKE(COALESCE(s.p_promo_name, w.p_promo_name), '.*Discount.*')
ORDER BY
  store_sales_total DESC,
  web_sales_total DESC
LIMIT 100
