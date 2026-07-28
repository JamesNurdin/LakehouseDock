WITH
  ss_sales AS (
    SELECT
      cs.ss_customer_sk AS c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      s.s_store_sk,
      SUM(cs.ss_ext_sales_price) AS total_sales,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(cs.ss_ext_sales_price) DESC) AS rn_store
    FROM store_sales cs
    JOIN customer c ON cs.ss_customer_sk = c.c_customer_sk
    JOIN store s ON cs.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON cs.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(c.c_last_name, '^A.*')
      AND c.c_birth_country LIKE 'U%'
    GROUP BY cs.ss_customer_sk, c.c_first_name, c.c_last_name, s.s_store_name, s.s_store_sk
    HAVING SUM(cs.ss_ext_sales_price) > 1000
  ),

  catalog_sales_agg AS (
    SELECT
      cs2.cs_bill_customer_sk AS c_customer_sk,
      c2.c_first_name,
      c2.c_last_name,
      'Catalog' AS source,
      SUM(cs2.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs2
    JOIN customer c2 ON cs2.cs_bill_customer_sk = c2.c_customer_sk
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
      AND regexp_like(c2.c_last_name, '^A.*')
    GROUP BY cs2.cs_bill_customer_sk, c2.c_first_name, c2.c_last_name
  ),

  combined AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales, 'Store' AS source
    FROM ss_sales
    UNION ALL
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales, source
    FROM catalog_sales_agg
  ),

  filtered AS (
    SELECT *
    FROM combined c
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
      WHERE sr.sr_customer_sk = c.c_customer_sk
        AND dr.d_year = 2001
    )
  ),

  final AS (
    SELECT
      c_customer_sk,
      CONCAT(c_first_name, ' ', c_last_name) AS full_name,
      source,
      total_sales,
      ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank_overall
    FROM filtered
  )
SELECT
  c_customer_sk,
  full_name,
  source,
  total_sales,
  rank_overall
FROM final
WHERE rank_overall <= 100
ORDER BY total_sales DESC
LIMIT 100
