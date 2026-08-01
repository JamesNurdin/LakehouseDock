WITH base AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_number_employees,
        cc.cc_call_center_id,
        cc.cc_employees,
        d.d_year,
        d.d_current_quarter
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE s.s_street_type IN ('Circle', 'Court', 'Boulevard')
      AND s.s_country = 'United States'
      AND cc.cc_country = 'United States'
      AND cc.cc_tax_percentage > 5.00
      AND d.d_year BETWEEN 1998 AND 2002
      AND d.d_current_quarter = 'N'
      AND cc.cc_employees > (SELECT MAX(s_number_employees) FROM store WHERE s_state = 'TX')
),
set_a AS (
    SELECT s_store_id FROM base WHERE s_state = 'TX'
),
set_b AS (
    SELECT s_store_id FROM store WHERE s_city = 'Spring'
),
-- Subtract one key set from another
diff AS (
    SELECT s_store_id FROM set_a EXCEPT SELECT s_store_id FROM set_b
),
-- Union two distinct result sets
unioned AS (
    SELECT s_store_id, s_city, s_state FROM base WHERE s_state = 'CA'
    UNION
    SELECT s_store_id, s_city, s_state FROM base WHERE s_state = 'FL'
),
ranked AS (
    SELECT
        u.s_store_id,
        u.s_city,
        u.s_state,
        ROW_NUMBER() OVER (PARTITION BY u.s_state ORDER BY u.s_store_id) AS rn,
        RANK() OVER (PARTITION BY u.s_state ORDER BY b.s_number_employees DESC) AS rnk_emp
    FROM (
        SELECT * FROM unioned
    ) u
    JOIN base b
        ON u.s_store_id = b.s_store_id
)
SELECT
    r.s_store_id,
    r.s_city,
    r.s_state,
    r.rn,
    r.rnk_emp
FROM ranked r
WHERE r.s_store_id IN (SELECT s_store_id FROM diff)
ORDER BY r.rn
LIMIT 100
