WITH
  -- Store sales filtered with string processing and date filter
  store_sales_filtered AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_store_sk AS store_sk,
      ss.ss_customer_sk,
      ss.ss_net_paid,
      regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_word,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
      CASE WHEN regexp_like(c.c_email_address, '.*@example\\.com') THEN true ELSE false END AS is_example_email
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(p.p_channel_details, 'force')
  ),

  -- Web sales filtered with similar logic
  web_sales_filtered AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_bill_customer_sk AS customer_sk,
      ws.ws_net_paid,
      regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_word,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
      CASE WHEN c.c_email_address LIKE '%@example.com' THEN true ELSE false END AS is_example_email
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_purpose LIKE '%Unknown%'
  ),

  -- Stores that have sales but never appear in returns
  store_sales_keys AS (
    SELECT DISTINCT ss.ss_store_sk AS store_sk
    FROM store_sales ss
  ),
  store_returns_keys AS (
    SELECT DISTINCT sr.sr_store_sk AS store_sk
    FROM store_returns sr
  ),
  stores_with_sales_not_returns AS (
    SELECT store_sk FROM store_sales_keys
    EXCEPT
    SELECT store_sk FROM store_returns_keys
  ),

  -- Aggregation on store sales (only stores that satisfy the EXCEPT condition)
  agg_store AS (
    SELECT
      ssf.promo_word,
      ssf.is_example_email,
      ssf.store_sk,
      SUM(ssf.ss_net_paid) AS total_net_paid,
      COUNT(*) AS cnt,
      pl.promo_len
    FROM store_sales_filtered ssf
    JOIN stores_with_sales_not_returns swr ON ssf.store_sk = swr.store_sk
    CROSS JOIN LATERAL (
      SELECT length(ssf.promo_word) AS promo_len
    ) pl
    GROUP BY ssf.promo_word, ssf.is_example_email, ssf.store_sk, pl.promo_len
  ),

  -- Aggregation on web sales (store_sk is not applicable, set to NULL)
  agg_web AS (
    SELECT
      wsf.promo_word,
      wsf.is_example_email,
      NULL AS store_sk,
      SUM(wsf.ws_net_paid) AS total_net_paid,
      COUNT(*) AS cnt,
      pl.promo_len
    FROM web_sales_filtered wsf
    CROSS JOIN LATERAL (
      SELECT length(wsf.promo_word) AS promo_len
    ) pl
    GROUP BY wsf.promo_word, wsf.is_example_email, pl.promo_len
  ),

  -- Union of the two aggregated result sets (deduplication implicit)
  unioned AS (
    SELECT promo_word, is_example_email, store_sk, total_net_paid, cnt, promo_len FROM agg_store
    UNION
    SELECT promo_word, is_example_email, store_sk, total_net_paid, cnt, promo_len FROM agg_web
  )
SELECT
  promo_word,
  is_example_email,
  SUM(total_net_paid) AS agg_net_paid,
  SUM(cnt) AS total_cnt,
  MAX(promo_len) AS max_promo_len
FROM unioned
WHERE promo_word IS NOT NULL
GROUP BY promo_word, is_example_email
ORDER BY agg_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
