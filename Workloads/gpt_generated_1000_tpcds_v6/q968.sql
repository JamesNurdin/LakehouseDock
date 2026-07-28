WITH returns_agg AS (
  SELECT
    i.i_item_id,
    d.d_year,
    d.d_month_seq,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'Regular' END AS day_type
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, d.d_year, d.d_month_seq, d.d_holiday
),
sales_agg AS (
  SELECT
    i.i_item_id,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    COUNT(*) AS sales_cnt,
    CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'Regular' END AS day_type
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_item_id, d.d_year, d.d_month_seq, d.d_holiday
)
SELECT
  'Return' AS source_type,
  r.i_item_id,
  r.d_year,
  r.d_month_seq,
  r.total_return_amt AS amount,
  r.return_cnt AS cnt,
  r.day_type,
  (
    SELECT MAX(cs2.cs_net_paid_inc_ship_tax)
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE cs2.cs_item_sk = i.i_item_sk
      AND d2.d_year = 2001
  ) AS max_sales_for_item
FROM returns_agg r
JOIN item i ON r.i_item_id = i.i_item_id
WHERE r.total_return_amt > 0

UNION ALL

SELECT
  'Sale' AS source_type,
  s.i_item_id,
  s.d_year,
  s.d_month_seq,
  s.total_sales AS amount,
  s.sales_cnt AS cnt,
  s.day_type,
  (
    SELECT MAX(cs2.cs_net_paid_inc_ship_tax)
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE cs2.cs_item_sk = i.i_item_sk
      AND d2.d_year = 2001
  ) AS max_sales_for_item
FROM sales_agg s
JOIN item i ON s.i_item_id = i.i_item_id
WHERE s.total_sales > 0
ORDER BY source_type, d_year DESC, d_month_seq, i_item_id
LIMIT 100
