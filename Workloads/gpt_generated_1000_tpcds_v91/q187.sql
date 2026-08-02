WITH cc_word_counts AS (
  SELECT
    cc.cc_call_center_sk,
    COUNT(DISTINCT word) AS word_count
  FROM call_center cc
  CROSS JOIN UNNEST(split(cc.cc_name, ' ')) AS t(word)
  GROUP BY cc.cc_call_center_sk
),
base_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_name,
    p.p_promo_name,
    i.i_product_name,
    i.i_item_desc,
    cc_word_counts.word_count,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_tax) AS total_return_tax,
    COUNT(*) AS return_count
  FROM web_returns wr
  JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN call_center cc
    ON cc.cc_open_date_sk = d_wr.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d_wr.d_date_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  LEFT JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
    AND p.p_start_date_sk = d_wr.d_date_sk
  LEFT JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  LEFT JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
  JOIN cc_word_counts
    ON cc_word_counts.cc_call_center_sk = cc.cc_call_center_sk
  WHERE REGEXP_LIKE(cc.cc_name, 'Center')
    AND REGEXP_LIKE(i.i_product_name, '\\d+')
    AND p.p_promo_name LIKE '%Discount%'
    AND d_wr.d_following_holiday = 'N'
    AND d_wr.d_year = 2002
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_name,
    p.p_promo_name,
    i.i_product_name,
    i.i_item_desc,
    cc_word_counts.word_count
)
SELECT
  ba.cc_call_center_id,
  ba.cc_name,
  concat(ba.cc_name, ' - ', ba.s_store_name) AS cc_store_combined,
  ba.p_promo_name,
  ba.i_product_name,
  regexp_extract(ba.i_product_name, '(\\d+)', 1) AS product_code,
  substring(ba.i_item_desc, 1, 15) AS item_desc_prefix,
  ba.total_return_amt,
  ba.total_return_tax,
  ba.return_count,
  ba.word_count,
  ba.total_return_amt / SUM(ba.total_return_amt) OVER () AS pct_of_total_returns,
  ROW_NUMBER() OVER (ORDER BY ba.total_return_amt DESC) AS return_rank
FROM base_agg ba
ORDER BY ba.total_return_amt DESC
LIMIT 100
