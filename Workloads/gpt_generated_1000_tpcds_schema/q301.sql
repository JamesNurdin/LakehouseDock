WITH filtered_2001 AS (
  SELECT
    i.i_brand AS brand,
    i.i_class AS class,
    d.d_year AS year,
    SUM(wr.wr_return_amt) AS total_return,
    AVG(wr.wr_return_tax) AS avg_tax,
    COUNT(*) AS cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND d.d_holiday = 'N'
    AND d.d_quarter_seq = 14
    AND i.i_class = 'pants'
    AND i.i_brand_id = 5
    AND wr.wr_return_tax > 10
    AND EXISTS (
      SELECT 1
      FROM web_returns wr2
      WHERE wr2.wr_item_sk = i.i_item_sk
        AND wr2.wr_return_amt > 100
    )
  GROUP BY i.i_brand, i.i_class, d.d_year
  HAVING COUNT(*) > 1
),
filtered_2002 AS (
  SELECT
    i.i_brand AS brand,
    i.i_class AS class,
    d.d_year AS year,
    SUM(wr.wr_return_amt) AS total_return,
    AVG(wr.wr_return_tax) AS avg_tax,
    COUNT(*) AS cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2002
    AND d.d_holiday = 'Y'
    AND d.d_quarter_seq = 5
    AND i.i_class = 'fragrances'
    AND i.i_brand_id = 7
    AND wr.wr_return_tax > 20
  GROUP BY i.i_brand, i.i_class, d.d_year
  HAVING COUNT(*) > 1
)
SELECT brand, class, year, total_return, avg_tax, cnt
FROM filtered_2002
EXCEPT
SELECT brand, class, year, total_return, avg_tax, cnt
FROM filtered_2001
ORDER BY total_return DESC
LIMIT 100
