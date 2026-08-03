WITH sampled_store_returns AS (
  SELECT *
  FROM store_returns
  TABLESAMPLE BERNOULLI (10)
),
item_with_array AS (
  SELECT
    i_item_sk,
    i_item_id,
    i_product_name,
    ARRAY[i_item_id, i_product_name] AS attrs
  FROM item
),
unrolled_item AS (
  SELECT
    i_item_sk,
    attr
  FROM item_with_array
  CROSS JOIN UNNEST(attrs) AS t(attr)
),
common_store_keys AS (
  SELECT sr_store_sk AS store_sk
  FROM sampled_store_returns
  WHERE sr_return_amt > 500
  INTERSECT
  SELECT s_store_sk
  FROM store
  WHERE s_state IN ('CA','TX')
),
first_set AS (
  SELECT
    i.i_brand,
    s.s_state,
    r.r_reason_desc,
    ui.attr AS attribute_value,
    SUM(sr.sr_return_amt) AS total_return_amt,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY SUM(sr.sr_return_amt) DESC) AS brand_return_rank
  FROM sampled_store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN unrolled_item ui ON i.i_item_sk = ui.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_store_sk IN (SELECT store_sk FROM common_store_keys)
    AND sr.sr_return_quantity >= 2
    AND i.i_current_price BETWEEN 10 AND 1000
    AND r.r_reason_desc LIKE '%price%'
  GROUP BY CUBE(i.i_brand, s.s_state, r.r_reason_desc, ui.attr)
  HAVING SUM(sr.sr_return_amt) > 1000
),
second_set AS (
  SELECT
    i.i_brand,
    s.s_state,
    r.r_reason_desc,
    ui.attr AS attribute_value,
    SUM(sr.sr_return_amt) AS total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(sr.sr_return_amt) DESC) AS state_row_num
  FROM sampled_store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN unrolled_item ui ON i.i_item_sk = ui.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_store_sk IN (SELECT store_sk FROM common_store_keys)
    AND sr.sr_return_quantity <= 5
    AND i.i_wholesale_cost < 500
    AND s.s_tax_percentage > 0
  GROUP BY CUBE(i.i_brand, s.s_state, r.r_reason_desc, ui.attr)
  HAVING SUM(sr.sr_return_amt) BETWEEN 500 AND 2000
)
SELECT *
FROM first_set
UNION
SELECT *
FROM second_set
ORDER BY total_return_amt DESC
LIMIT 100
