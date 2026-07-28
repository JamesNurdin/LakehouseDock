WITH
    -- First sub‑set: fiscal year 1910, all return times
    returns_a AS (
        SELECT
            sr.sr_store_sk,
            d.d_fy_year,
            sr.sr_return_amt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE d.d_fy_year = 1910
          AND NOT EXISTS (
              SELECT 1
              FROM web_site w
              WHERE w.web_open_date_sk = sr.sr_returned_date_sk
          )
    ),
    agg_a AS (
        SELECT
            sr_store_sk,
            d_fy_year,
            SUM(sr_return_amt) AS total_return_amt
        FROM returns_a
        GROUP BY sr_store_sk, d_fy_year
    ),
    window_a AS (
        SELECT
            sr_store_sk,
            d_fy_year,
            total_return_amt,
            ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY total_return_amt DESC) AS rn
        FROM agg_a
    ),
    -- Second sub‑set: fiscal year 1911, only returns made between 09:00 and 17:00
    returns_b AS (
        SELECT
            sr.sr_store_sk,
            d.d_fy_year,
            sr.sr_return_amt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE d.d_fy_year = 1911
          AND t.t_hour BETWEEN 9 AND 17
          AND NOT EXISTS (
              SELECT 1
              FROM web_site w
              WHERE w.web_close_date_sk = sr.sr_returned_date_sk
          )
    ),
    agg_b AS (
        SELECT
            sr_store_sk,
            d_fy_year,
            SUM(sr_return_amt) AS total_return_amt
        FROM returns_b
        GROUP BY sr_store_sk, d_fy_year
    ),
    window_b AS (
        SELECT
            sr_store_sk,
            d_fy_year,
            total_return_amt,
            ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY total_return_amt DESC) AS rn
        FROM agg_b
    )
SELECT sr_store_sk,
       d_fy_year,
       total_return_amt,
       rn
FROM window_a
UNION ALL
SELECT sr_store_sk,
       d_fy_year,
       total_return_amt,
       rn
FROM window_b
LIMIT 100
