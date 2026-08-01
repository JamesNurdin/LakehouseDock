WITH
  store_city AS (
    SELECT DISTINCT
      s.s_store_sk,
      s.s_store_name,
      CONCAT(s.s_city, ', ', s.s_state) AS location,
      SUBSTRING(s.s_hours FROM 1 FOR 5) AS hour_prefix
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(s.s_city, '^A.*')
      AND s.s_city LIKE '%ton%'
  ),
  returns_no_sales AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_returned_date_sk,
      sr.sr_store_sk
    FROM store_returns sr
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_sales ss
      WHERE ss.ss_ticket_number = sr.sr_ticket_number
    )
  ),
  full_joined AS (
    SELECT
      COALESCE(sc.s_store_sk, rns.sr_store_sk) AS store_sk,
      sc.s_store_name,
      sc.location,
      sc.hour_prefix,
      rns.sr_ticket_number,
      rns.sr_returned_date_sk
    FROM store_city sc
    FULL OUTER JOIN returns_no_sales rns
      ON sc.s_store_sk = rns.sr_store_sk
  )
SELECT DISTINCT
  fj.store_sk,
  fj.s_store_name,
  fj.location,
  fj.hour_prefix,
  fj.sr_ticket_number,
  fj.sr_returned_date_sk,
  l.city_first_word
FROM full_joined fj
CROSS JOIN LATERAL (
  SELECT REGEXP_EXTRACT(fj.location, '(\\w+)', 1) AS city_first_word
) AS l
WHERE fj.store_sk IS NOT NULL
EXCEPT
SELECT
  fj.store_sk,
  fj.s_store_name,
  fj.location,
  fj.hour_prefix,
  fj.sr_ticket_number,
  fj.sr_returned_date_sk,
  l.city_first_word
FROM full_joined fj
CROSS JOIN LATERAL (
  SELECT REGEXP_EXTRACT(fj.location, '(\\w+)', 1) AS city_first_word
) AS l
WHERE fj.sr_ticket_number IS NULL
LIMIT 100
