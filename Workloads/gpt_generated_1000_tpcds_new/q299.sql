WITH
  sales_base AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_net_paid_inc_tax AS net_sales,
      CASE WHEN ss.ss_net_paid_inc_tax > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
      (
        SELECT SUM(sr.sr_net_loss)
        FROM store_returns sr
        WHERE sr.sr_store_sk = ss.ss_store_sk
          AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
      ) AS store_return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  returns_base AS (
    SELECT
      NULL AS ss_store_sk,
      cr.cr_returned_date_sk AS ss_sold_date_sk,
      cr.cr_net_loss AS net_sales,
      CASE WHEN cr.cr_net_loss > 500 THEN 'High' ELSE 'Low' END AS sales_category,
      NULL AS store_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  union_data AS (
    SELECT * FROM sales_base
    UNION ALL
    SELECT * FROM returns_base
  ),
  inventory_agg AS (
    SELECT
      inv.inv_date_sk AS ss_sold_date_sk,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY inv.inv_date_sk
  ),
  full_joined AS (
    SELECT
      u.ss_sold_date_sk,
      u.ss_store_sk,
      u.net_sales,
      u.sales_category,
      u.store_return_loss,
      i.total_inventory
    FROM union_data u
    FULL OUTER JOIN inventory_agg i
      ON u.ss_sold_date_sk = i.ss_sold_date_sk
  )
SELECT
  d.d_year,
  s.s_store_name,
  fj.sales_category,
  SUM(fj.net_sales) AS total_net_sales,
  SUM(fj.store_return_loss) AS total_return_loss,
  SUM(fj.total_inventory) AS total_inventory,
  CASE
    WHEN SUM(fj.net_sales) IS NULL THEN 'No Sales'
    WHEN SUM(fj.net_sales) > 5000 THEN 'Very High'
    ELSE 'Normal'
  END AS overall_category
FROM full_joined fj
LEFT JOIN date_dim d ON fj.ss_sold_date_sk = d.d_date_sk
LEFT JOIN store s ON fj.ss_store_sk = s.s_store_sk
GROUP BY ROLLUP (d.d_year, s.s_store_name, fj.sales_category)
ORDER BY d.d_year NULLS LAST,
         s.s_store_name NULLS LAST,
         fj.sales_category NULLS LAST
LIMIT 100
