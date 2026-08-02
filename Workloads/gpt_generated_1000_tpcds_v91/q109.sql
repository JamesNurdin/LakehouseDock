WITH
  /* Aggregate catalog returns per returned date */
  cr_agg AS (
    SELECT
      cr_returned_date_sk,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_return_ship_cost) AS total_ship_cost,
      AVG(cr_return_amount) AS avg_return_amount,
      COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 100                     -- filter predicate 1
      AND cr_refunded_customer_sk IN (6521310, 11582572) -- filter predicate 2
    GROUP BY cr_returned_date_sk
  ),
  /* Union two subsets of web pages */
  wp_union AS (
    SELECT
      wp_web_page_sk,
      wp_creation_date_sk,
      wp_char_count,
      wp_type
    FROM web_page
    WHERE wp_type = 'home'
      AND wp_char_count > 2000
    UNION ALL
    SELECT
      wp_web_page_sk,
      wp_creation_date_sk,
      wp_char_count,
      wp_type
    FROM web_page
    WHERE wp_type = 'product'
      AND wp_char_count > 2000
  ),
  /* Join the pre‑aggregated returns with date_dim and the filtered web pages */
  joined AS (
    SELECT
      d.d_year,
      d.d_moy,
      d.d_fy_quarter_seq,
      cr_agg.total_return_amount,
      cr_agg.total_ship_cost,
      cr_agg.cnt_returns,
      wp_union.wp_web_page_sk,
      wp_union.wp_char_count,
      wp_union.wp_type
    FROM cr_agg
    JOIN date_dim d
      ON cr_agg.cr_returned_date_sk = d.d_date_sk
    JOIN wp_union
      ON wp_union.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_moy = 5                     -- filter predicate 3 (sample month)
      AND d.d_fy_quarter_seq = 14        -- filter predicate 4 (sample quarter seq)
      AND wp_union.wp_char_count > 2500  -- filter predicate 5 (realistic range)
  ),
  /* Group the joined data and apply a scalar sub‑query filter */
  agg AS (
    SELECT
      d_year,
      d_moy,
      d_fy_quarter_seq,
      SUM(total_return_amount) AS sum_return_amount,
      AVG(total_ship_cost) AS avg_ship_cost,
      COUNT(DISTINCT wp_web_page_sk) AS distinct_page_cnt,
      MAX(wp_char_count) AS max_char_count
    FROM joined
    WHERE total_return_amount > (
        SELECT AVG(cr_return_amount)
        FROM catalog_returns
        WHERE cr_refunded_customer_sk = 6521310
      )
    GROUP BY d_year, d_moy, d_fy_quarter_seq
    HAVING SUM(total_return_amount) > 5000
  )
SELECT
  d_year,
  d_moy,
  d_fy_quarter_seq,
  sum_return_amount,
  avg_ship_cost,
  distinct_page_cnt,
  max_char_count,
  ROW_NUMBER() OVER (ORDER BY sum_return_amount DESC) AS rn
FROM agg
ORDER BY sum_return_amount DESC
LIMIT 100
