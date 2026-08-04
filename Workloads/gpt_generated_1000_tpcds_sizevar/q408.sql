WITH
  /* Store keys after exclusion via EXCEPT */
  key_set AS (
    SELECT DISTINCT s_store_sk FROM store WHERE s_state = 'TX'
    EXCEPT
    SELECT DISTINCT ss_store_sk FROM store_sales WHERE ss_ext_discount_amt > 1000
  ),

  /* Sales fact enriched with all dimension tables */
  sales_joined AS (
    SELECT
      ss.ss_sold_time_sk,
      ss.ss_hdemo_sk,
      ss.ss_store_sk,
      ss.ss_ext_discount_amt,
      ss.ss_net_profit,
      ss.ss_quantity,
      td.t_hour,
      td.t_meal_time,
      hd.hd_income_band_sk,
      hd.hd_dep_count,
      s.s_store_name,
      s.s_state,
      s.s_city
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'TX'
      AND hd.hd_income_band_sk = 15
      AND td.t_hour BETWEEN 9 AND 17
      AND ss.ss_ext_discount_amt > 100
  ),

  /* All stores in TX (distinct) – will be full‑outer‑joined with the sales side */
  stores_tx AS (
    SELECT DISTINCT
      s_store_sk,
      s_store_name,
      s_state,
      s_city
    FROM store
    WHERE s_state = 'TX'
  )
SELECT
  COALESCE(sj.ss_store_sk, st.s_store_sk) AS store_sk,
  COALESCE(sj.s_store_name, st.s_store_name) AS store_name,
  COALESCE(sj.s_state, st.s_state) AS state,
  COALESCE(sj.s_city, st.s_city) AS city,
  sj.t_hour,
  sj.hd_income_band_sk,
  SUM(sj.ss_net_profit) AS total_net_profit,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(sj.s_state, st.s_state) ORDER BY SUM(sj.ss_net_profit) DESC) AS profit_rank
FROM stores_tx st
FULL OUTER JOIN sales_joined sj ON st.s_store_sk = sj.ss_store_sk
WHERE COALESCE(sj.ss_store_sk, st.s_store_sk) IN (SELECT s_store_sk FROM key_set)
GROUP BY
  COALESCE(sj.ss_store_sk, st.s_store_sk),
  COALESCE(sj.s_store_name, st.s_store_name),
  COALESCE(sj.s_state, st.s_state),
  COALESCE(sj.s_city, st.s_city),
  sj.t_hour,
  sj.hd_income_band_sk
ORDER BY total_net_profit DESC
LIMIT 100
