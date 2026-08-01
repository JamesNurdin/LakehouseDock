WITH start_pages AS (
  SELECT cp.cp_catalog_page_id AS key_id
  FROM catalog_page cp
  JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND cp.cp_catalog_number > 10
),
end_pages AS (
  SELECT cp.cp_catalog_page_id AS key_id
  FROM catalog_page cp
  JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND cp.cp_type = 'A'
),
intersect_pages AS (
  SELECT key_id FROM start_pages
  INTERSECT
  SELECT key_id FROM end_pages
),
high_profit_stores AS (
  SELECT s.s_store_id AS key_id
  FROM store s
  JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND ss.ss_net_profit > (
      SELECT max(ss2.ss_net_profit)
      FROM store_sales ss2
      WHERE ss2.ss_sold_date_sk = (
        SELECT max(d2.d_date_sk)
        FROM date_dim d2
        WHERE d2.d_year = 2002
      )
    )
    AND ss.ss_net_paid > (SELECT avg(ss3.ss_net_paid) FROM store_sales ss3)
)
SELECT key_id
FROM intersect_pages
UNION
SELECT key_id
FROM high_profit_stores
ORDER BY key_id
OFFSET 10
LIMIT 100
