WITH
  sales_agg AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      CONCAT('Store: ', s.s_store_name) AS store_label,
      REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1) AS promo_code_extracted,
      SUM(ss.ss_net_profit) AS total_net_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)clearance')
      AND ca.ca_city LIKE 'A%'
      AND s.s_gmt_offset = -5.00
    GROUP BY
      s.s_store_id,
      s.s_store_name,
      CONCAT('Store: ', s.s_store_name),
      REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1)
  ),
  returns_agg AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      CONCAT('Store: ', s.s_store_name) AS store_label,
      REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1) AS promo_code_extracted,
      SUM(wr.wr_refunded_cash) AS total_refunded_cash,
      COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE wr.wr_refunded_cash > 500
    GROUP BY
      s.s_store_id,
      s.s_store_name,
      CONCAT('Store: ', s.s_store_name),
      REGEXP_EXTRACT(p.p_promo_name, '(\\d+)', 1)
  ),
  stores_to_keep AS (
    SELECT s_store_id, store_label, promo_code_extracted
    FROM sales_agg
    EXCEPT
    SELECT s_store_id, store_label, promo_code_extracted
    FROM returns_agg
  )
SELECT
  sa.s_store_id,
  sa.store_label,
  sa.promo_code_extracted,
  sa.total_net_profit,
  sa.sales_cnt
FROM sales_agg sa
JOIN stores_to_keep sk
  ON sa.s_store_id = sk.s_store_id
  AND sa.store_label = sk.store_label
  AND sa.promo_code_extracted = sk.promo_code_extracted
ORDER BY sa.total_net_profit DESC
LIMIT 100
