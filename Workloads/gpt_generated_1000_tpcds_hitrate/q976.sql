WITH
  sr_agg AS (
    SELECT sr_returned_date_sk,
           COUNT(*) AS store_return_cnt,
           SUM(sr_return_amt) AS store_return_total,
           AVG(sr_return_amt) AS store_return_avg
    FROM store_returns
    WHERE sr_ticket_number IN (1, 2, 6)
      AND sr_return_quantity > 0
    GROUP BY sr_returned_date_sk
  ),
  wr_agg AS (
    SELECT wr_returned_date_sk,
           COUNT(*) AS web_return_cnt,
           SUM(wr_return_amt) AS web_return_total
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_fee < 5.0
    GROUP BY wr_returned_date_sk
  ),
  dim_vals AS (
    SELECT 1 AS grp UNION ALL SELECT 2 AS grp
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY d1.d_year, d1.d_month_seq) AS row_num,
  d1.d_year,
  d1.d_month_seq,
  sr_agg.store_return_cnt,
  sr_agg.store_return_total,
  wr_agg.web_return_cnt,
  wr_agg.web_return_total,
  SUM(CASE WHEN wp.wp_type = 'ad' THEN wr_agg.web_return_total ELSE 0 END) AS ad_return_total,
  COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
  dv.grp
FROM sr_agg
JOIN date_dim d1 ON sr_agg.sr_returned_date_sk = d1.d_date_sk
JOIN wr_agg ON wr_agg.wr_returned_date_sk = d1.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
CROSS JOIN dim_vals dv
WHERE d1.d_fy_year = 1919
  AND d1.d_week_seq BETWEEN 5 AND 15
  AND d1.d_current_quarter = 'Y'
  AND wp.wp_autogen_flag = 'N'
  AND wp.wp_type IN ('ad', 'order')
  AND wp.wp_char_count > 1000
GROUP BY d1.d_year,
         d1.d_month_seq,
         sr_agg.store_return_cnt,
         sr_agg.store_return_total,
         wr_agg.web_return_cnt,
         wr_agg.web_return_total,
         dv.grp
ORDER BY d1.d_year DESC, d1.d_month_seq ASC
LIMIT 100
