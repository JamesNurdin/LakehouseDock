WITH agg_a AS (
    SELECT
        d.d_year AS year,
        sm.sm_type AS ship_type,
        sm.sm_code AS ship_code,
        CONCAT(sm.sm_type, '_', sm.sm_code) AS type_code,
        MIN(regexp_extract(sm.sm_contract, '\\d+', 0)) AS contract_digits,
        MIN(substring(sm.sm_contract, 1, 3)) AS contract_prefix,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_holiday = 'N'
      AND sm.sm_contract LIKE '%Z%'
      AND regexp_like(sm.sm_contract, '^.{5}[Zz]')
    GROUP BY CUBE (d.d_year, sm.sm_type, sm.sm_code)
),
agg_b AS (
    SELECT
        d.d_year AS year,
        sm.sm_type AS ship_type,
        sm.sm_code AS ship_code,
        CONCAT(sm.sm_type, '_', sm.sm_code) AS type_code,
        MIN(regexp_extract(sm.sm_contract, '\\d+', 0)) AS contract_digits,
        MIN(substring(sm.sm_contract, 1, 3)) AS contract_prefix,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_weekend = 'Y'
      AND sm.sm_code LIKE 'A%'
      AND regexp_like(sm.sm_contract, '[0-9]{2,}$')
      AND sm.sm_contract LIKE '%2mM8l%'
    GROUP BY CUBE (d.d_year, sm.sm_type, sm.sm_code)
)
SELECT
    year,
    ship_type,
    ship_code,
    type_code,
    contract_digits,
    contract_prefix,
    total_sales,
    order_count,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
FROM (
    SELECT * FROM agg_a
    UNION
    SELECT * FROM agg_b
) u
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM (
        SELECT total_sales FROM agg_a
        UNION ALL
        SELECT total_sales FROM agg_b
    ) t
)
ORDER BY total_sales DESC, rn
LIMIT 100
