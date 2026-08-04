WITH
  ret_data AS (
    SELECT
      cr_returning_hdemo_sk AS demo_sk,
      cr_return_amount AS amount,
      CASE WHEN cr_reversed_charge > 500 THEN 'High' ELSE 'Low' END AS charge_category,
      cr_returned_date_sk AS date_sk
    FROM catalog_returns TABLESAMPLE BERNOULLI (10)
    JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
    JOIN household_demographics ON catalog_returns.cr_returning_hdemo_sk = household_demographics.hd_demo_sk
    WHERE cr_return_amount > 100
  ),
  web_data AS (
    SELECT
      ws_bill_hdemo_sk AS demo_sk,
      ws_ext_sales_price AS amount,
      CASE WHEN ws_ext_discount_amt > 50 THEN 'Discounted' ELSE 'FullPrice' END AS charge_category,
      ws_sold_date_sk AS date_sk
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    JOIN household_demographics ON web_sales.ws_bill_hdemo_sk = household_demographics.hd_demo_sk
    WHERE ws_ext_sales_price > 100
  ),
  filtered_ret AS (
    SELECT
      cr_returning_hdemo_sk AS demo_sk,
      cr_return_amount AS amount,
      CASE WHEN cr_reversed_charge > 500 THEN 'High' ELSE 'Low' END AS charge_category,
      cr_returned_date_sk AS date_sk
    FROM catalog_returns
    JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
    WHERE cr_return_amount BETWEEN 200 AND 500
  )
SELECT demo_sk, amount, charge_category, date_sk
FROM (
  SELECT demo_sk, amount, charge_category, date_sk FROM ret_data
  UNION
  SELECT demo_sk, amount, charge_category, date_sk FROM web_data
) AS union_set
INTERSECT
SELECT demo_sk, amount, charge_category, date_sk FROM filtered_ret
ORDER BY amount DESC, demo_sk
LIMIT 100
