WITH store_full AS (
   SELECT
       sr.sr_store_sk,
       sr.sr_return_time_sk,
       sr.sr_return_amt,
       sr.sr_store_credit,
       sr.sr_reason_sk,
       s.s_store_name,
       s.s_city,
       s.s_state
   FROM store_returns sr
   FULL OUTER JOIN store s
       ON sr.sr_store_sk = s.s_store_sk
), web_dim AS (
   SELECT
       ws.ws_web_site_sk,
       ws.ws_sold_time_sk,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       w.web_site_id,
       w.web_name,
       w.web_city,
       w.web_state
   FROM web_sales ws
   RIGHT OUTER JOIN web_site w
       ON ws.ws_web_site_sk = w.web_site_sk
), time_f AS (
   SELECT
       t.t_time_sk,
       t.t_shift,
       t.t_minute,
       t.t_second
   FROM time_dim t
   WHERE t.t_shift = 'first' AND t.t_minute < 10
), store_time AS (
   SELECT
       sf.*,
       tf.t_shift,
       tf.t_minute,
       tf.t_second,
       tf.t_time_sk
   FROM store_full sf
   LEFT JOIN time_f tf
       ON sf.sr_return_time_sk = tf.t_time_sk
), web_time AS (
   SELECT
       wd.*,
       tf.t_shift AS w_shift,
       tf.t_minute AS w_minute,
       tf.t_second AS w_second,
       tf.t_time_sk
   FROM web_dim wd
   LEFT JOIN time_f tf
       ON wd.ws_sold_time_sk = tf.t_time_sk
)
SELECT
   COALESCE(st.s_store_name, 'UNKNOWN') AS store_name,
   st.s_city,
   st.s_state,
   SUM(COALESCE(st.sr_return_amt, 0)) AS total_return_amount,
   COUNT(st.sr_store_sk) AS return_rows,
   COALESCE(wd.web_name, 'NO_SITE') AS web_name,
   CONCAT(wd.web_city, '-', wd.web_state) AS web_location,
   CASE
       WHEN regexp_like(wd.web_name, '^A.*') THEN 'StartsWithA'
       ELSE 'Other'
   END AS web_name_category,
   regexp_extract(wd.web_name, '(\\w+)', 1) AS web_name_first_word,
   SUBSTRING(COALESCE(st.s_store_name, '' ) FROM 1 FOR 5) AS store_name_prefix,
   SUM(COALESCE(wd.ws_ext_sales_price, 0)) AS total_sales_price,
   SUM(COALESCE(wd.ws_net_profit, 0)) AS total_net_profit,
   COALESCE(st.t_shift, wd.w_shift) AS shift,
   COALESCE(st.t_minute, wd.w_minute) AS minute,
   COALESCE(st.t_second, wd.w_second) AS second
FROM store_time st
FULL OUTER JOIN web_time wd
   ON st.t_time_sk = wd.t_time_sk
WHERE COALESCE(wd.web_name, '') LIKE '%Shop%'
  AND regexp_like(COALESCE(st.s_store_name, ''), '^.*Store$')
GROUP BY
   COALESCE(st.s_store_name, 'UNKNOWN'),
   st.s_city,
   st.s_state,
   COALESCE(wd.web_name, 'NO_SITE'),
   CONCAT(wd.web_city, '-', wd.web_state),
   CASE
       WHEN regexp_like(wd.web_name, '^A.*') THEN 'StartsWithA'
       ELSE 'Other'
   END,
   regexp_extract(wd.web_name, '(\\w+)', 1),
   SUBSTRING(COALESCE(st.s_store_name, '' ) FROM 1 FOR 5),
   COALESCE(st.t_shift, wd.w_shift),
   COALESCE(st.t_minute, wd.w_minute),
   COALESCE(st.t_second, wd.w_second)
ORDER BY total_return_amount DESC
OFFSET 0 ROWS
LIMIT 100
