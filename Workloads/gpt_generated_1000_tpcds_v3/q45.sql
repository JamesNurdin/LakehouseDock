WITH filtered_returns AS (
  SELECT
    sr.sr_return_time_sk,
    sr.sr_item_sk,
    sr.sr_store_sk,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    i.i_item_desc,
    i.i_brand,
    i.i_category,
    s.s_store_name,
    s.s_market_desc,
    t.t_hour,
    regexp_extract(i.i_item_desc, '(\\d{4})', 1) AS four_digit_code,
    CASE
      WHEN sr.sr_return_amt > 500 THEN 'Large'
      WHEN sr.sr_return_amt > 200 THEN 'Medium'
      ELSE 'Small'
    END AS return_size
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
    AND s.s_market_desc LIKE '%regional%'
)
SELECT
  fr.return_size,
  fr.four_digit_code,
  COUNT(*) AS return_cnt,
  SUM(fr.sr_return_amt) AS total_return_amount,
  AVG(fr.sr_return_quantity) AS avg_quantity,
  CONCAT(fr.i_brand, '-', SUBSTRING(fr.i_item_desc, 1, 10)) AS brand_desc_snippet
FROM filtered_returns fr
GROUP BY
  fr.return_size,
  fr.four_digit_code,
  fr.i_brand,
  fr.i_item_desc
ORDER BY total_return_amount DESC
LIMIT 100
