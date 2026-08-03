WITH
  cs_agg AS (
    SELECT
      i.i_brand AS brand,
      i.i_category AS category,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      AVG(cs.cs_ext_discount_amt) AS avg_discount,
      (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_name LIKE '%Clearance%'
      ) AS max_clearance_cost
    FROM
      catalog_sales cs
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
      regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND i.i_color LIKE 'R%'
    GROUP BY
      GROUPING SETS (
        (i.i_brand, i.i_category),
        (i.i_brand),
        (i.i_category),
        ()
      )
  ),
  ss_agg AS (
    SELECT
      i.i_brand AS brand,
      i.i_category AS category,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      AVG(ss.ss_ext_discount_amt) AS avg_discount,
      (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_name LIKE '%Clearance%'
      ) AS max_clearance_cost
    FROM
      store_sales ss
      JOIN item i ON ss.ss_item_sk = i.i_item_sk
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
      regexp_like(s.s_store_name, '^A.*')
      AND s.s_city LIKE '%York%'
    GROUP BY
      GROUPING SETS (
        (i.i_brand, i.i_category),
        (i.i_brand),
        (i.i_category),
        ()
      )
  ),
  unioned AS (
    SELECT brand, category, total_sales, avg_discount, max_clearance_cost FROM cs_agg
    UNION DISTINCT
    SELECT brand, category, total_sales, avg_discount, max_clearance_cost FROM ss_agg
  )
SELECT
  unioned.brand,
  unioned.category,
  unioned.total_sales,
  unioned.avg_discount,
  unioned.max_clearance_cost,
  ROW_NUMBER() OVER (ORDER BY unioned.total_sales DESC) AS row_num
FROM
  unioned
LIMIT 100
