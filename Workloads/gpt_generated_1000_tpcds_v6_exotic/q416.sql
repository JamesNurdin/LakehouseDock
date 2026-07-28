WITH
  sales_agg AS (
    SELECT
      i.i_category,
      d.d_year,
      d.d_month_seq AS month_seq,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})') AS extracted_digits
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(i.i_item_desc, '\\d{3}')
    GROUP BY i.i_category, d.d_year, d.d_month_seq, REGEXP_EXTRACT(i.i_item_desc, '(\\d{3})')
  ),
  returns_agg AS (
    SELECT
      i.i_category,
      d.d_year,
      d.d_month_seq AS month_seq,
      SUM(wr.wr_net_loss) AS total_loss,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND LOWER(r.r_reason_desc) LIKE '%damaged%'
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  )
SELECT
  s.i_category,
  s.d_year,
  CONCAT('Month_', CAST(s.month_seq AS varchar)) AS month_label,
  s.total_profit,
  COALESCE(r.total_loss, 0) AS total_loss,
  (s.total_profit - COALESCE(r.total_loss, 0)) AS net_contribution,
  SUBSTR(s.i_category, 1, 3) AS cat_abbr,
  CONCAT('Cat ', SUBSTR(s.i_category, 1, 3)) AS cat_label
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.i_category = r.i_category
  AND s.d_year = r.d_year
  AND s.month_seq = r.month_seq
WHERE s.total_profit > 1000
ORDER BY net_contribution DESC
LIMIT 100
