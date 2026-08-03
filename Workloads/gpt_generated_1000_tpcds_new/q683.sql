WITH
  store_agg AS (
    SELECT
      ss_item_sk,
      ss_promo_sk,
      SUM(ss_net_paid) AS store_net_paid,
      COUNT(*) AS store_sales_cnt,
      AVG(ss_ext_discount_amt) AS store_avg_discount
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_net_paid > 1000
      AND ss_ext_discount_amt BETWEEN 0 AND 500
      AND ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ss_item_sk, ss_promo_sk
  ),
  catalog_agg AS (
    SELECT
      cs_item_sk,
      cs_promo_sk,
      SUM(cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax,
      COUNT(*) AS catalog_sales_cnt
    FROM tpcds.catalog_sales
    WHERE cs_ext_discount_amt > 300
      AND cs_net_paid_inc_tax < 20000
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY cs_item_sk, cs_promo_sk
  )
SELECT
  i.i_category,
  i.i_class,
  p.p_promo_name,
  SUM(sa.store_net_paid + ca.catalog_net_paid_inc_tax) AS total_net_paid,
  SUM(sa.store_sales_cnt + ca.catalog_sales_cnt) AS total_sales_cnt,
  CASE
    WHEN SUM(sa.store_net_paid + ca.catalog_net_paid_inc_tax) > 20000 THEN 'High'
    ELSE 'Medium'
  END AS revenue_band
FROM store_agg sa
JOIN catalog_agg ca
  ON sa.ss_item_sk = ca.cs_item_sk
  AND sa.ss_promo_sk = ca.cs_promo_sk
JOIN tpcds.item i
  ON i.i_item_sk = sa.ss_item_sk
JOIN tpcds.promotion p
  ON p.p_promo_sk = sa.ss_promo_sk
WHERE i.i_item_sk NOT IN (
        SELECT i2.i_item_sk
        FROM tpcds.item i2
        WHERE i2.i_color = 'red'
      )
GROUP BY i.i_category, i.i_class, p.p_promo_name
HAVING SUM(sa.store_net_paid + ca.catalog_net_paid_inc_tax) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
