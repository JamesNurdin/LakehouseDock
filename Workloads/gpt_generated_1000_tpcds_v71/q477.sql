WITH base_join AS (
  SELECT
    d_cr.d_year AS year,
    hd_cr_ret.hd_income_band_sk AS income_band,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_amt_inc_tax,
    cr.cr_net_loss,
    sr.sr_return_amt_inc_tax,
    sr.sr_net_loss,
    wr.wr_return_amt_inc_tax,
    wr.wr_net_loss,
    wp.wp_type,
    CASE
      WHEN cr.cr_return_amount > 200 THEN 'HighReturn'
      ELSE 'LowReturn'
    END AS cr_return_category,
    cr.cr_order_number
  FROM catalog_returns cr
  JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
  JOIN household_demographics hd_cr_ret
    ON cr.cr_returning_hdemo_sk = hd_cr_ret.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_cr.d_date_sk
  JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_cr.d_date_sk
  JOIN household_demographics hd_wr_ret
    ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
  WHERE d_cr.d_year = 2001
    AND hd_cr_ret.hd_income_band_sk > 5
    AND cr.cr_return_amount > 100
    AND wp.wp_type = 'Content'
    AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_order_number = cr.cr_order_number
        AND wr2.wr_return_amt_inc_tax > 500
    )
),
agg AS (
  SELECT
    year,
    income_band,
    cr_return_category,
    SUM(cr_return_amt_inc_tax) AS sum_cr_return_inc_tax,
    SUM(sr_return_amt_inc_tax) AS sum_sr_return_inc_tax,
    SUM(wr_return_amt_inc_tax) AS sum_wr_return_inc_tax,
    SUM(cr_net_loss + sr_net_loss + wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr_order_number) AS distinct_orders
  FROM base_join
  GROUP BY year, income_band, cr_return_category
)
SELECT
  year,
  income_band,
  cr_return_category,
  sum_cr_return_inc_tax,
  sum_sr_return_inc_tax,
  sum_wr_return_inc_tax,
  total_net_loss,
  distinct_orders,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
  AVG(total_net_loss) OVER (PARTITION BY income_band) AS avg_loss_by_income
FROM agg
WHERE total_net_loss > (SELECT AVG(total_net_loss) FROM agg)
  AND distinct_orders > 5
ORDER BY loss_rank
LIMIT 100
