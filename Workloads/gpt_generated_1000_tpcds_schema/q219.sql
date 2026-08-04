WITH
store_data AS (
  SELECT DISTINCT
    cd.cd_gender,
    i.i_category,
    sr.sr_returned_date_sk AS return_date_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    i.i_current_price,
    i.i_wholesale_cost,
    ARRAY[i.i_current_price, i.i_wholesale_cost] AS price_array,
    SUM(sr.sr_return_amt) OVER (
        PARTITION BY cd.cd_gender
        ORDER BY sr.sr_returned_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_return_sum,
    LAG(sr.sr_return_amt) OVER (
        PARTITION BY cd.cd_gender
        ORDER BY sr.sr_returned_date_sk
    ) AS prior_return_amt
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE sr.sr_return_amt > 10
),
store_unnested AS (
  SELECT
    cd_gender,
    i_category,
    return_date_sk,
    price_value,
    running_return_sum,
    prior_return_amt
  FROM store_data
  CROSS JOIN UNNEST(price_array) AS t(price_value)
),
web_data AS (
  SELECT DISTINCT
    cd.cd_gender,
    i.i_category,
    wr.wr_returned_date_sk AS return_date_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    i.i_current_price,
    i.i_wholesale_cost,
    ARRAY[i.i_current_price, i.i_wholesale_cost] AS price_array,
    SUM(wr.wr_return_amt) OVER (
        PARTITION BY cd.cd_gender
        ORDER BY wr.wr_returned_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_return_sum,
    LAG(wr.wr_return_amt) OVER (
        PARTITION BY cd.cd_gender
        ORDER BY wr.wr_returned_date_sk
    ) AS prior_return_amt
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_return_amt > 10
),
web_unnested AS (
  SELECT
    cd_gender,
    i_category,
    return_date_sk,
    price_value,
    running_return_sum,
    prior_return_amt
  FROM web_data
  CROSS JOIN UNNEST(price_array) AS t(price_value)
)
SELECT
  gender,
  category,
  price_value,
  SUM(running_return_sum) AS total_running_sum,
  MAX(prior_return_amt) AS max_prior_return
FROM (
  SELECT
    cd_gender AS gender,
    i_category AS category,
    price_value,
    running_return_sum,
    prior_return_amt
  FROM store_unnested
  UNION ALL
  SELECT
    cd_gender AS gender,
    i_category AS category,
    price_value,
    running_return_sum,
    prior_return_amt
  FROM web_unnested
) combined
GROUP BY gender, category, price_value
HAVING SUM(running_return_sum) > 500
ORDER BY total_running_sum DESC
LIMIT 100
