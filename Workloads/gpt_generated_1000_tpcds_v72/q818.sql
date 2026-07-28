WITH
  sr_agg AS (
    SELECT
      sr_item_sk,
      sr_return_time_sk,
      sr_cdemo_sk,
      SUM(sr_return_amt)          AS sum_store_return_amt,
      SUM(sr_return_tax)          AS sum_store_return_tax,
      SUM(sr_return_quantity)    AS sum_store_return_qty,
      COUNT(*)                    AS cnt_store_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_return_tax >= 0
      AND sr_return_time_sk IS NOT NULL
      AND sr_item_sk IS NOT NULL
      AND sr_cdemo_sk IS NOT NULL
    GROUP BY sr_item_sk, sr_return_time_sk, sr_cdemo_sk
  ),
  wr_agg AS (
    SELECT
      wr_item_sk,
      wr_returned_time_sk,
      wr_refunded_cdemo_sk,
      SUM(wr_return_amt)          AS sum_web_return_amt,
      SUM(wr_return_tax)          AS sum_web_return_tax,
      SUM(wr_return_quantity)    AS sum_web_return_qty,
      COUNT(*)                    AS cnt_web_returns
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
      AND wr_return_tax >= 0
    GROUP BY wr_item_sk, wr_returned_time_sk, wr_refunded_cdemo_sk
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  cd.cd_gender,
  cd.cd_education_status,
  td.t_shift,
  td.t_sub_shift,
  p.p_promo_name,
  SUM(sr.sum_store_return_amt)            AS total_store_return_amt,
  SUM(wr.sum_web_return_amt)              AS total_web_return_amt,
  SUM(sr.sum_store_return_qty + wr.sum_web_return_qty) AS total_return_quantity,
  AVG(sr.sum_store_return_tax)            AS avg_store_return_tax,
  AVG(wr.sum_web_return_tax)              AS avg_web_return_tax,
  COUNT(DISTINCT sr.sr_item_sk)           AS distinct_store_items,
  COUNT(DISTINCT wr.wr_item_sk)           AS distinct_web_items
FROM sr_agg sr
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
LEFT JOIN wr_agg wr
  ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE p.p_cost > 500
  AND p.p_channel_event = 'N'
  AND i.i_current_price BETWEEN 20 AND 200
  AND td.t_shift = 'first'
  AND td.t_sub_shift = 'morning'
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
GROUP BY
  i.i_item_id,
  i.i_product_name,
  cd.cd_gender,
  cd.cd_education_status,
  td.t_shift,
  td.t_sub_shift,
  p.p_promo_name
ORDER BY total_store_return_amt DESC
LIMIT 100
