WITH sampled_items AS (
   SELECT *
   FROM item
   TABLESAMPLE BERNOULLI (10)
   WHERE regexp_like(i_formulation, '[a-z]+')
),
item_words AS (
   SELECT i_item_sk,
          word,
          length(word) AS word_len
   FROM sampled_items
   CROSS JOIN UNNEST(split(i_item_desc, ' ')) AS t(word)
),
returns_items AS (
   SELECT
       sr.sr_item_sk,
       sr.sr_return_amt,
       sr.sr_customer_sk,
       sr.sr_return_time_sk,
       i.i_brand,
       i.i_category,
       i.i_formulation,
       i.i_current_price,
       i.i_item_id,
       w.word,
       w.word_len
   FROM store_returns sr
   FULL OUTER JOIN sampled_items i
        ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN item_words w
        ON i.i_item_sk = w.i_item_sk
),
extended AS (
   SELECT
       ri.*,
       c.c_first_name,
       c.c_last_name,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       t.t_hour
   FROM returns_items ri
   LEFT JOIN customer c
        ON ri.sr_customer_sk = c.c_customer_sk
   LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN time_dim t
        ON ri.sr_return_time_sk = t.t_time_sk
)
SELECT
    COALESCE(e.i_brand, 'UNKNOWN') AS brand,
    COALESCE(e.i_category, 'UNKNOWN') AS category,
    regexp_extract(e.i_formulation, '[a-z]+', 0) AS formulation_alpha,
    SUM(COALESCE(e.sr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT e.sr_customer_sk) AS distinct_customers,
    AVG(e.word_len) AS avg_word_length,
    CONCAT('Brand_', COALESCE(e.i_brand, '0')) AS brand_label,
    AVG(e.ib_lower_bound) AS avg_income_lower,
    AVG(e.t_hour) AS avg_return_hour
FROM extended e
WHERE (
        e.i_formulation IS NOT NULL
        AND regexp_like(e.i_formulation, '[0-9]{5}[a-z]+[0-9]{5}')
      )
   OR e.i_formulation IS NULL
  AND e.i_item_id LIKE 'ITEM%'
GROUP BY
    COALESCE(e.i_brand, 'UNKNOWN'),
    COALESCE(e.i_category, 'UNKNOWN'),
    regexp_extract(e.i_formulation, '[a-z]+', 0),
    CONCAT('Brand_', COALESCE(e.i_brand, '0'))
ORDER BY total_return_amount DESC
LIMIT 100
