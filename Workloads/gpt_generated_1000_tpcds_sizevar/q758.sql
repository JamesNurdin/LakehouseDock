WITH sampled_sr AS (
   SELECT *
   FROM store_returns
   TABLESAMPLE BERNOULLI (10)
),
filtered_sr AS (
   SELECT 
          sr.sr_store_sk,
          sr.sr_customer_sk,
          sr.sr_returned_date_sk,
          sr.sr_return_amt,
          sr.sr_net_loss,
          c.c_first_name,
          c.c_last_name,
          s.s_store_id,
          s.s_store_name,
          s.s_state,
          d.d_year,
          ARRAY[s.s_store_sk, sr.sr_customer_sk] AS key_array
   FROM sampled_sr sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE regexp_like(s.s_store_name, '^A.*')               -- name starts with "A"
     AND s.s_store_name LIKE '%Market%'                     -- contains the word Market
),
anti_joined AS (
   SELECT f.*
   FROM filtered_sr f
   WHERE NOT EXISTS (
         SELECT 1
         FROM web_returns wr
         WHERE wr.wr_returned_date_sk = f.sr_returned_date_sk
           AND wr.wr_refunded_customer_sk = f.sr_customer_sk
   )
),
unnested_keys AS (
   SELECT a.*, k AS key_element
   FROM anti_joined a
   CROSS JOIN UNNEST(a.key_array) AS t(k)
),
agg AS (
   SELECT
          s_store_id,
          s_store_name,
          s_state,
          d_year,
          CONCAT(s_store_name, ' - ', CAST(d_year AS varchar)) AS store_year,
          regexp_extract(s_store_name, '^([^ ]+)', 1) AS first_word,
          SUM(sr_return_amt) AS total_return_amt,
          SUM(sr_net_loss) AS total_net_loss,
          COUNT(*) AS return_cnt,
          COUNT(DISTINCT key_element) AS distinct_key_elements
   FROM unnested_keys
   GROUP BY s_store_id, s_store_name, s_state, d_year,
            CONCAT(s_store_name, ' - ', CAST(d_year AS varchar)),
            regexp_extract(s_store_name, '^([^ ]+)', 1)
),
stores_a AS (
   SELECT s.s_store_id
   FROM store s
   WHERE s.s_state = 'CA'
),
stores_b AS (
   SELECT s.s_store_id
   FROM store s
   WHERE s.s_store_name LIKE '%Mall%'
)
SELECT
       a.store_year,
       a.first_word,
       a.total_return_amt,
       a.total_net_loss,
       a.return_cnt,
       a.distinct_key_elements
FROM agg a
WHERE a.s_store_id IN (
      SELECT s_store_id FROM stores_a
      INTERSECT
      SELECT s_store_id FROM stores_b
)
ORDER BY a.total_return_amt DESC
LIMIT 100
