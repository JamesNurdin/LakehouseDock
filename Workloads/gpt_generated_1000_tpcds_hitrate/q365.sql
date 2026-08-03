WITH base AS (
   SELECT
       d.d_year,
       d.d_date,
       i.i_item_id,
       i.i_category,
       i.i_current_price,
       i.i_brand,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       wr.wr_return_amt,
       wr.wr_return_quantity,
       cc.cc_name,
       cp.cp_type,
       w.w_warehouse_name,
       p.p_promo_name,
       ws.web_name,
       cd.cd_gender
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
),
filter_a AS (
   SELECT DISTINCT d_year, i_category
   FROM base
   WHERE i_current_price > 50
     AND hd_buy_potential = '>10000'
     AND ib_lower_bound >= 50000
     AND d_year BETWEEN 2000 AND 2002
),
filter_b AS (
   SELECT DISTINCT d_year, i_category
   FROM base
   WHERE cr_return_amount > 0
     AND cr_return_quantity > 0
     AND wr_return_amt > 0
     AND wr_return_quantity > 0
),
common_year_category AS (
   SELECT d_year AS year, i_category AS category FROM filter_a
   INTERSECT
   SELECT d_year AS year, i_category AS category FROM filter_b
),
agg AS (
   SELECT
       d_year,
       i_category,
       SUM(COALESCE(cr_return_amount, 0) + COALESCE(wr_return_amt, 0)) AS total_return_amount,
       COUNT(DISTINCT i_item_id) AS distinct_items
   FROM base
   GROUP BY ROLLUP (d_year, i_category)
)
SELECT
    COALESCE(a.d_year, -1) AS year,
    COALESCE(a.i_category, 'All') AS category,
    a.total_return_amount,
    a.distinct_items,
    ROW_NUMBER() OVER (ORDER BY a.total_return_amount DESC) AS rn
FROM agg a
JOIN common_year_category c
  ON a.d_year = c.year AND a.i_category = c.category
ORDER BY a.total_return_amount DESC
LIMIT 100
