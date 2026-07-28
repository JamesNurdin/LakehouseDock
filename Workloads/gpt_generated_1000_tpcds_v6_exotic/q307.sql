WITH
  sales_summary AS (
    SELECT
      d.d_year AS year,
      d.d_month_seq AS month_seq,
      i.i_category AS category,
      'sales' AS source,
      SUM(ss.ss_ext_sales_price) AS amount
    FROM store_sales AS ss
    JOIN date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item AS i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion AS p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_category = 'Electronics'
      AND p.p_channel_tv = 'N'
    GROUP BY GROUPING SETS (
      (d.d_year, d.d_month_seq, i.i_category),
      (d.d_year, d.d_month_seq),
      (d.d_year),
      ()
    )
  ),
  returns_summary AS (
    SELECT
      d.d_year AS year,
      d.d_month_seq AS month_seq,
      i.i_category AS category,
      'returns' AS source,
      SUM(sr.sr_return_amt) AS amount
    FROM store_returns AS sr
    JOIN date_dim AS d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item AS i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason AS r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.i_category = 'Electronics'
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY GROUPING SETS (
      (d.d_year, d.d_month_seq, i.i_category),
      (d.d_year, d.d_month_seq),
      (d.d_year),
      ()
    )
  )
SELECT *
FROM sales_summary
UNION ALL
SELECT *
FROM returns_summary
ORDER BY year DESC, month_seq DESC, category, source
LIMIT 100
