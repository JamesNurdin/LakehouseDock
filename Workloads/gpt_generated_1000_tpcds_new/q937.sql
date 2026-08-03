WITH recent_closed AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        s.s_number_employees
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
      AND d.d_current_day = 'N'
),
older_closed AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        d.d_year
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 1995
      AND d.d_current_day = 'N'
),
-- Subtract stores closed in 1995 from those closed in 1998
diff AS (
    SELECT
        rc.s_store_sk,
        rc.s_store_name,
        rc.d_year,
        rc.s_number_employees
    FROM recent_closed rc
    EXCEPT
    SELECT
        oc.s_store_sk,
        oc.s_store_name,
        oc.d_year,
        NULL AS s_number_employees
    FROM older_closed oc
),
-- Small dimension for a cross join (few distinct day names)
small_days AS (
    SELECT DISTINCT d_day_name
    FROM date_dim
    WHERE d_day_name IS NOT NULL
    LIMIT 5
)
SELECT
    d.s_store_sk,
    d.s_store_name,
    d.d_year,
    d.s_number_employees,
    sd.d_day_name,
    l.scaled_emp
FROM diff d
CROSS JOIN small_days sd
CROSS JOIN LATERAL (
    SELECT d.s_number_employees * 2 AS scaled_emp
) l
ORDER BY d.d_year DESC, d.s_store_sk
LIMIT 100
