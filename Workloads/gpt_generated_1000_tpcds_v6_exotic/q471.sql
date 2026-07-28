WITH base AS (
   SELECT
     s.s_store_id,
     MAX(s.s_store_name) AS s_store_name,
     i.i_category,
     SUM(ss.ss_net_paid) AS total_sales,
     SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
     SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns
   FROM store_sales ss
   JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
   JOIN item i                      ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p                 ON ss.ss_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr         ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN web_returns wr             ON wr.wr_item_sk = i.i_item_sk
   WHERE s.s_rec_start_date >= DATE '1999-01-01'
     AND i.i_manufact_id IN (214, 350, 630)
     AND p.p_discount_active = 'Y'
     AND cp.cp_type = 'Seasonal'
     AND ss.ss_quantity > 1
   GROUP BY ROLLUP (s.s_store_id, i.i_category)
)
SELECT
  s_store_id,
  s_store_name,
  i_category,
  total_sales,
  total_catalog_returns,
  total_web_returns,
  (total_sales - (total_catalog_returns + total_web_returns)) AS net_revenue,
  CASE WHEN total_sales > 100000 THEN 'High' ELSE 'Medium' END AS sales_tier,
  ROW_NUMBER() OVER (
    PARTITION BY s_store_id
    ORDER BY (total_sales - (total_catalog_returns + total_web_returns)) DESC
  ) AS revenue_rank,
  (SELECT AVG(total_sales) FROM base) AS overall_avg_sales
FROM base
WHERE NOT (s_store_id IS NULL AND i_category IS NULL)
ORDER BY net_revenue DESC
LIMIT 100
