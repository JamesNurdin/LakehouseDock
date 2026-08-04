WITH sampled_date AS (
    SELECT *
    FROM date_dim
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_state,
        ws.web_tax_percentage,
        dd.d_date,
        dd.d_year,
        dd.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY ws.web_state ORDER BY dd.d_date DESC) AS rn_state_desc,
        ROW_NUMBER() OVER (PARTITION BY ws.web_state ORDER BY dd.d_date ASC)  AS rn_state_asc
    FROM sampled_date dd
    FULL OUTER JOIN web_site ws
        ON (ws.web_open_date_sk = dd.d_date_sk OR ws.web_close_date_sk = dd.d_date_sk)
    WHERE
        ws.web_tax_percentage BETWEEN 0.01 AND 0.10
        AND ws.web_zip IN ('88054', '48059', '38048')
        AND dd.d_year >= 2000
        AND dd.d_month_seq BETWEEN 1200 AND 1300
        AND ws.web_mkt_id IS NOT NULL
),
first_select AS (
    SELECT
        web_site_sk,
        web_name,
        web_state,
        web_tax_percentage,
        d_date,
        d_year,
        rn_state_desc AS rn_state
    FROM joined
    WHERE rn_state_desc <= 5
),
second_select AS (
    SELECT
        web_site_sk,
        web_name,
        web_state,
        web_tax_percentage,
        d_date,
        d_year,
        rn_state_asc AS rn_state
    FROM joined
    WHERE d_year = 2001
),
unioned AS (
    SELECT web_site_sk, web_name, web_state, web_tax_percentage, d_date, d_year, rn_state
    FROM first_select
    UNION
    SELECT web_site_sk, web_name, web_state, web_tax_percentage, d_date, d_year, rn_state
    FROM second_select
)
SELECT
    u.web_site_sk,
    u.web_name,
    u.web_state,
    u.web_tax_percentage,
    u.d_date,
    u.d_year,
    u.rn_state
FROM unioned u
WHERE NOT EXISTS (
    SELECT 1
    FROM web_site ws2
    WHERE ws2.web_site_sk = u.web_site_sk
      AND ws2.web_tax_percentage > 0.09
)
ORDER BY u.d_year DESC, u.rn_state
LIMIT 100
