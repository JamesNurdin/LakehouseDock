WITH base AS (
   SELECT
       cr.cr_returned_date_sk,
       d.d_year,
       cr.cr_item_sk,
       i.i_category,
       i.i_class,
       i.i_current_price,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_net_loss,
       c.c_customer_sk,
       c.c_birth_country,
       ca.ca_state,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       r.r_reason_desc,
       ARRAY[CAST(i.i_current_price AS double), CAST(cr.cr_return_amount AS double)] AS price_amount_arr
   FROM catalog_returns cr
   JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i                   ON cr.cr_item_sk = i.i_item_sk
   JOIN customer c               ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN customer_address ca      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
   LEFT JOIN store s             ON s.s_closed_date_sk = d.d_date_sk
   LEFT JOIN web_page wp         ON wp.wp_creation_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr      ON wr.wr_order_number = cr.cr_order_number
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_current_price > 10
     AND cr.cr_return_quantity > 0
     AND ib.ib_lower_bound >= 20000
     AND ca.ca_state IN ('CA','TX','NY')
     AND r.r_reason_desc LIKE '%damaged%'
),
agg1 AS (
   SELECT
       b.d_year,
       b.i_category,
       SUM(b.cr_return_amount) AS total_return_amount,
       SUM(b.cr_return_quantity) AS total_quantity,
       AVG(b.i_current_price) AS avg_price,
       COUNT(*) AS cnt
   FROM base b
   GROUP BY GROUPING SETS ((b.d_year, b.i_category), (b.d_year))
),
final AS (
   SELECT
       b.d_year,
       COALESCE(b.i_category, 'ALL') AS category,
       a.total_return_amount,
       a.total_quantity,
       a.avg_price,
       CASE
           WHEN a.total_return_amount > 50000 THEN 'HIGH_LOSS'
           WHEN a.total_return_amount > 20000 THEN 'MEDIUM_LOSS'
           ELSE 'LOW_LOSS'
       END AS loss_level,
       (SELECT AVG(i_current_price) FROM base b2 WHERE b2.d_year = b.d_year) AS year_avg_price,
       u.price_amount AS unnested_value
   FROM base b
   JOIN agg1 a
     ON a.d_year = b.d_year
    AND (a.i_category = b.i_category OR a.i_category IS NULL)
   CROSS JOIN UNNEST(b.price_amount_arr) AS u(price_amount)
   WHERE EXISTS (
       SELECT 1 FROM web_returns wr2
       WHERE wr2.wr_refunded_customer_sk = b.c_customer_sk
         AND wr2.wr_returned_date_sk = b.cr_returned_date_sk
   )
     AND b.cr_net_loss > 0
     AND b.ib_upper_bound <= 200000
),
result AS (
   SELECT
       d_year,
       category,
       loss_level,
       SUM(total_return_amount) AS sum_return_amount,
       SUM(total_quantity) AS sum_quantity,
       AVG(year_avg_price) AS avg_year_price,
       COUNT(DISTINCT unnested_value) AS distinct_unnested_vals
   FROM final
   GROUP BY GROUPING SETS ((d_year, category, loss_level), (d_year, loss_level))
   HAVING SUM(total_return_amount) > 10000
)
SELECT *
FROM result
ORDER BY d_year DESC, sum_return_amount DESC
LIMIT 100
