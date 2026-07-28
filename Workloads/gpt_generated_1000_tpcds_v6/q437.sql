WITH
  filtered_items AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_current_price,
      regexp_extract(i.i_product_name, '(\\d{4})') AS year_in_name
    FROM tpcds.item i
    WHERE regexp_like(i.i_product_name, '^.*[0-9]{4}.*$')
      AND i.i_product_name LIKE '%COOL%'
  ),
  catalog_agg AS (
    SELECT
      p.p_promo_name,
      d.d_year AS year,
      f.i_item_sk,
      f.i_product_name,
      SUM(cs.cs_net_paid) AS total_net_paid,
      (
        SELECT AVG(cs2.cs_net_paid)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_item_sk = f.i_item_sk
      ) AS avg_item_net_paid
    FROM tpcds.catalog_sales cs
    JOIN filtered_items f ON cs.cs_item_sk = f.i_item_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE p.p_promo_name LIKE '%Discount%'
      AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr
        WHERE wr.wr_item_sk = f.i_item_sk
          AND wr.wr_reason_sk = (
            SELECT r.r_reason_sk
            FROM tpcds.reason r
            WHERE r.r_reason_desc = 'Customer not satisfied'
            LIMIT 1
          )
      )
    GROUP BY p.p_promo_name, d.d_year, f.i_item_sk, f.i_product_name
    HAVING SUM(cs.cs_net_paid) > 10000
  ),
  store_agg AS (
    SELECT
      p.p_promo_name,
      d.d_year AS year,
      f.i_item_sk,
      f.i_product_name,
      SUM(ss.ss_net_paid) AS total_net_paid,
      (
        SELECT AVG(cs2.cs_net_paid)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_item_sk = f.i_item_sk
      ) AS avg_item_net_paid
    FROM tpcds.store_sales ss
    JOIN filtered_items f ON ss.ss_item_sk = f.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE p.p_promo_name LIKE '%Discount%'
      AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr
        WHERE wr.wr_item_sk = f.i_item_sk
          AND wr.wr_reason_sk = (
            SELECT r.r_reason_sk
            FROM tpcds.reason r
            WHERE r.r_reason_desc = 'Customer not satisfied'
            LIMIT 1
          )
      )
    GROUP BY p.p_promo_name, d.d_year, f.i_item_sk, f.i_product_name
    HAVING SUM(ss.ss_net_paid) > 10000
  ),
  union_all AS (
    SELECT DISTINCT promo_name, year, i_item_sk, i_product_name, total_net_paid, avg_item_net_paid
    FROM (
      SELECT p_promo_name AS promo_name, year, i_item_sk, i_product_name, total_net_paid, avg_item_net_paid FROM catalog_agg
      UNION ALL
      SELECT p_promo_name AS promo_name, year, i_item_sk, i_product_name, total_net_paid, avg_item_net_paid FROM store_agg
    ) u
  )
SELECT
  promo_name,
  year,
  i_product_name,
  total_net_paid,
  avg_item_net_paid,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS rank_in_year,
  CONCAT('Promo_', CAST(year AS VARCHAR), '_', REPLACE(promo_name, ' ', '_')) AS promo_key
FROM union_all
WHERE promo_name LIKE '%Summer%'
ORDER BY total_net_paid DESC
LIMIT 100
