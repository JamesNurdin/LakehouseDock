WITH
  sampled_sales AS (
    SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
  ),
  sales_returns AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_net_paid,
      sr.sr_return_amt,
      ss.ss_net_paid - COALESCE(sr.sr_return_amt, 0) AS net_after_return
    FROM sampled_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
  ),
  agg_sales AS (
    SELECT d.d_year, SUM(sr.net_after_return) AS total_net
    FROM sales_returns sr
    JOIN date_dim d ON sr.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
  ),
  sampled_catalog AS (
    SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  catalog_returns_full AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price,
      cr.cr_return_amount,
      cs.cs_ext_sales_price - COALESCE(cr.cr_return_amount, 0) AS net_after_return
    FROM sampled_catalog cs
    FULL OUTER JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
      AND cs.cs_item_sk = cr.cr_item_sk
  ),
  agg_catalog AS (
    SELECT d.d_year, SUM(crf.net_after_return) AS total_net
    FROM catalog_returns_full crf
    JOIN date_dim d ON crf.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
  ),
  union_agg AS (
    SELECT d_year, total_net FROM agg_sales
    UNION
    SELECT d_year, total_net FROM agg_catalog
  ),
  promo_years AS (
    SELECT d.d_year
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
  ),
  sales_years AS (
    SELECT d_year FROM agg_sales
  ),
  common_years AS (
    SELECT d_year FROM sales_years
    INTERSECT
    SELECT d_year FROM promo_years
  )
SELECT u.d_year, u.total_net
FROM union_agg u
JOIN common_years cy ON u.d_year = cy.d_year
ORDER BY u.d_year DESC
LIMIT 100
