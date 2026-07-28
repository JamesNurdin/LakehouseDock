WITH sr_join AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_return_amt,
    sr.sr_fee,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    sr.sr_return_time_sk,
    st.s_store_name,
    st.s_state,
    st.s_country,
    st.s_street_name,
    st.s_zip,
    td.t_meal_time,
    td.t_am_pm,
    td.t_hour
  FROM store_returns sr
  JOIN store st ON sr.sr_store_sk = st.s_store_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  WHERE td.t_meal_time = 'dinner'
    AND st.s_country = 'United States'
    AND regexp_like(st.s_street_name, 'Park')
    AND st.s_store_name LIKE '%Store%'
)

SELECT
  r.s_state,
  r.s_store_name,
  CONCAT(r.s_state, '-', r.s_store_name) AS state_store_concat,
  substring(r.s_store_name, 1, 3) AS store_name_prefix,
  regexp_extract(r.s_zip, '(\\d{5})') AS zip_prefix,
  COUNT(*) AS total_returns,
  SUM(r.sr_return_amt) AS total_return_amount,
  AVG(r.sr_fee) AS avg_fee,
  SUM(r.sr_return_amt) / NULLIF(COUNT(*),0) AS avg_return_amt,
  ROW_NUMBER() OVER (PARTITION BY r.s_state ORDER BY SUM(r.sr_return_amt) DESC) AS state_rank
FROM sr_join r
GROUP BY
  r.s_state,
  r.s_store_name,
  CONCAT(r.s_state, '-', r.s_store_name),
  substring(r.s_store_name, 1, 3),
  regexp_extract(r.s_zip, '(\\d{5})')
HAVING SUM(r.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
