WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk            AS store_sk,
      CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name,
      SUM(ss.ss_quantity)      AS total_quantity,
      SUM(ss.ss_net_paid)      AS total_net_paid,
      SUM(ss.ss_net_profit)    AS total_net_profit,
      CASE
        WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
        WHEN SUM(ss.ss_net_profit) BETWEEN 1000 AND 10000 THEN 'Medium'
        ELSE 'Low'
      END                      AS profit_category
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE (i.i_product_name LIKE '%GREEN%'
           OR regexp_like(i.i_product_name, '(?i)red|blue'))
      AND s.s_store_name LIKE '%Store%'
    GROUP BY ss.ss_store_sk, s.s_store_name, s.s_city
  ),
  promo_counts AS (
    SELECT
      ss.ss_store_sk                              AS store_sk,
      COUNT(DISTINCT p.p_promo_name)              AS distinct_promo_cnt
    FROM store_sales ss
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_name IS NOT NULL
    GROUP BY ss.ss_store_sk
  ),
  product_codes AS (
    SELECT
      ss.ss_store_sk                                      AS store_sk,
      COUNT(DISTINCT regexp_extract(i.i_product_name, '(\\d{3})', 1)) AS distinct_code_cnt
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_extract(i.i_product_name, '(\\d{3})', 1) IS NOT NULL
    GROUP BY ss.ss_store_sk
  )
SELECT
  sa.store_full_name,
  sa.profit_category,
  sa.total_quantity,
  ROUND(sa.total_net_paid, 2)            AS total_net_paid,
  sa.total_net_profit,
  pc.distinct_promo_cnt,
  CASE
    WHEN pc.distinct_promo_cnt >= 5 THEN 'Promo_Rich'
    ELSE 'Promo_Poor'
  END                                 AS promo_richness,
  pc2.distinct_code_cnt
FROM sales_agg sa
JOIN promo_counts pc
  ON sa.store_sk = pc.store_sk
JOIN product_codes pc2
  ON sa.store_sk = pc2.store_sk
ORDER BY sa.total_net_paid DESC
LIMIT 100
