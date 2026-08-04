WITH
  -- Stores located in cities starting with 'San'
  city_stores AS (
    SELECT s_store_sk
    FROM store
    WHERE s_city LIKE 'San%'
  ),

  -- Stores whose name contains the word 'Super'
  regex_stores AS (
    SELECT s_store_sk
    FROM store
    WHERE regexp_like(s_store_name, 'Super')
  ),

  -- Stores that recorded any sales in the year 2020
  sales_2020_store_keys AS (
    SELECT DISTINCT ss.ss_store_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),

  -- Stores in San‑prefixed cities that did NOT have sales in 2020
  city_not_sales2020 AS (
    SELECT s_store_sk FROM city_stores
    EXCEPT
    SELECT ss_store_sk FROM sales_2020_store_keys
  ),

  -- Stores whose name matches the regex *and* had sales in 2020
  regex_and_sales2020 AS (
    SELECT s_store_sk FROM regex_stores
    INTERSECT
    SELECT ss_store_sk FROM sales_2020_store_keys
  ),

  -- Full outer join of sales and returns, keeping unmatched rows from both sides
  sales_returns_full AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_ext_sales_price,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      d.d_year,
      s.s_store_name,
      s.s_city,
      s.s_state,
      s.s_zip
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_store_sk = sr.sr_store_sk
    LEFT JOIN date_dim d
      ON COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) = d.d_date_sk
    LEFT JOIN store s
      ON COALESCE(ss.ss_store_sk, sr.sr_store_sk) = s.s_store_sk
  ),

  -- Aggregation per store and year with string manipulation
  agg AS (
    SELECT
      COALESCE(srfs.ss_store_sk, -1)                                     AS store_sk,
      COALESCE(s.s_store_name, 'UNKNOWN')                                 AS store_name,
      COALESCE(d.d_year, 0)                                                AS year,
      SUM(COALESCE(srfs.ss_ext_sales_price, 0))                           AS total_sales,
      SUM(COALESCE(srfs.sr_return_amt, 0))                                AS total_returns,
      COUNT(DISTINCT srfs.ss_ticket_number)                               AS txn_count,
      CONCAT(s.s_state, '-', s.s_zip)                                    AS location_code,
      CASE
        WHEN regexp_like(s.s_store_name, 'Super') THEN 'SuperStore'
        ELSE 'Regular'
      END                                                                AS store_type
    FROM sales_returns_full srfs
    LEFT JOIN store s ON srfs.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d ON srfs.ss_sold_date_sk = d.d_date_sk
    WHERE srfs.ss_store_sk IN (SELECT s_store_sk FROM regex_and_sales2020)
      AND s.s_city LIKE 'San%'
      AND EXISTS (
        SELECT 1
        FROM store_returns r
        WHERE r.sr_store_sk = srfs.ss_store_sk
          AND r.sr_return_tax > 50
      )
    GROUP BY
      COALESCE(srfs.ss_store_sk, -1),
      COALESCE(s.s_store_name, 'UNKNOWN'),
      COALESCE(d.d_year, 0),
      s.s_state,
      s.s_zip,
      CASE
        WHEN regexp_like(s.s_store_name, 'Super') THEN 'SuperStore'
        ELSE 'Regular'
      END
  )
SELECT
  store_sk,
  store_name,
  year,
  total_sales,
  total_returns,
  txn_count,
  location_code,
  store_type
FROM agg
ORDER BY total_sales DESC, store_sk
LIMIT 100
