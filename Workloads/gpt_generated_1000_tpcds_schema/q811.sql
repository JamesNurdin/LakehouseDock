WITH
  full_store_sales AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_store_sk,
      s.s_store_id,
      ss.ss_net_paid,
      CASE WHEN ss.ss_net_paid > 5000 THEN 'High' ELSE 'Low' END AS revenue_category,
      ss.ss_quantity
    FROM store_sales ss
    FULL OUTER JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
  ),

  lateral_profit AS (
    SELECT
      fss.ss_ticket_number,
      fss.s_store_id,
      fss.revenue_category,
      fss.ss_quantity,
      lp.total_store_profit
    FROM full_store_sales fss
    LEFT JOIN LATERAL (
      SELECT SUM(ss2.ss_net_profit) AS total_store_profit
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = fss.ss_store_sk
    ) lp ON TRUE
  ),

  -- stores that have any sales (used for the EXCEPT example)
  stores_with_sales AS (
    SELECT DISTINCT s_store_id
    FROM lateral_profit
    WHERE s_store_id IS NOT NULL
  ),

  -- all stores (derived from the store table)
  all_stores AS (
    SELECT s_store_id
    FROM store
  ),

  -- stores that never had a sale (EXCEPT operation)
  stores_without_sales AS (
    SELECT s_store_id FROM all_stores
    EXCEPT
    SELECT s_store_id FROM stores_with_sales
  ),

  -- a subset of catalog sales for a specific year
  catalog_sales_subset AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      d.d_year,
      cs.cs_net_paid AS catalog_net_paid,
      CASE WHEN cs.cs_net_paid > 1000 THEN 'Big' ELSE 'Small' END AS size_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- combine store‑sale rows with catalog‑sale rows (UNION ALL)
  combined AS (
    SELECT
      CAST(s_store_id AS varchar) AS identifier,
      revenue_category AS category,
      total_store_profit AS amount
    FROM lateral_profit
    UNION ALL
    SELECT
      CAST(cs_order_number AS varchar) AS identifier,
      size_category AS category,
      catalog_net_paid AS amount
    FROM catalog_sales_subset
  )

SELECT
  identifier,
  category,
  amount
FROM combined
ORDER BY amount DESC
OFFSET 10
LIMIT 100
