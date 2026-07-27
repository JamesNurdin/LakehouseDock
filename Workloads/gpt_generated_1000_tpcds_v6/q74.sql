WITH base_join AS (
    SELECT
        s.s_division_name,
        s.s_store_name,
        s.s_number_employees,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_return_ship_cost
    FROM store s
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
)
SELECT DISTINCT
    division,
    store_name,
    total_return_amt,
    total_refunded_cash
FROM (
    SELECT
        bj.s_division_name   AS division,
        bj.s_store_name      AS store_name,
        SUM(bj.sr_return_amt)       AS total_return_amt,
        SUM(bj.sr_refunded_cash)    AS total_refunded_cash
    FROM base_join bj
    WHERE bj.sr_return_ship_cost > 30
      AND bj.s_number_employees BETWEEN 240 AND 260
    GROUP BY bj.s_division_name, bj.s_store_name

    UNION ALL

    SELECT
        bj.s_division_name   AS division,
        bj.s_store_name      AS store_name,
        SUM(bj.sr_return_amt)       AS total_return_amt,
        SUM(bj.sr_refunded_cash)    AS total_refunded_cash
    FROM base_join bj
    WHERE bj.sr_refunded_cash < 100
      AND bj.s_number_employees < 250
    GROUP BY bj.s_division_name, bj.s_store_name
) AS combined
ORDER BY total_return_amt DESC
LIMIT 100
