WITH open_returns AS (
    SELECT
        s.s_store_name AS s_store_name,
        d.d_date AS d_date,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2020
      AND hd.hd_buy_potential = '5001-10000'
      AND s.s_country = 'United States'
      AND s.s_floor_space >= 8000000
      AND NOT EXISTS (
          SELECT 1
          FROM date_dim d_closure
          WHERE s.s_closed_date_sk = d_closure.d_date_sk
            AND d_closure.d_date <= d.d_date
      )
    GROUP BY s.s_store_name, d.d_date
),
closed_returns AS (
    SELECT
        s.s_store_name AS s_store_name,
        d.d_date AS d_date,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
    WHERE d.d_year = 2020
      AND hd.hd_buy_potential = '5001-10000'
      AND d.d_date >= d_closure.d_date
    GROUP BY s.s_store_name, d.d_date
)
SELECT s_store_name, d_date, total_return_amt, total_return_qty
FROM open_returns
EXCEPT
SELECT s_store_name, d_date, total_return_amt, total_return_qty
FROM closed_returns
LIMIT 100
