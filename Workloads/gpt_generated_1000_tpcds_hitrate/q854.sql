WITH recent_dates AS (
    SELECT d_date_sk,
           d_year
    FROM   date_dim
    WHERE  d_year = (SELECT max(d_year) FROM date_dim)
       AND d_month_seq BETWEEN 1200 AND 1202
)
SELECT
    s.s_store_name,
    rd.d_year,
    SUM(ss.ss_net_profit)                                 AS total_profit,
    COUNT(ss.ss_ticket_number)                            AS sales_cnt,
    MIN(CONCAT('Store_', CAST(s.s_store_sk AS VARCHAR)))  AS store_key_str,
    MIN(CASE WHEN regexp_like(cp.cp_description, '(?i)promo') THEN 'Promo' ELSE 'Other' END) AS description_type,
    MIN(regexp_extract(cp.cp_description, '(\\d+)', 1)) AS first_number_in_desc,
    MAX(t.t_meal_time)                                    AS sample_meal_time,
    MAX(v.letter)                                          AS sample_letter
FROM
    recent_dates rd
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = rd.d_date_sk
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = rd.d_date_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    CROSS JOIN (VALUES 'X', 'Y') AS v(letter)
WHERE
    s.s_state LIKE 'C%'
    AND regexp_like(s.s_store_name, '^A.*')
    AND cp.cp_description IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM   call_center cc
        WHERE  cc.cc_call_center_sk = cr.cr_call_center_sk
          AND  cc.cc_name LIKE 'Call%'
    )
GROUP BY
    GROUPING SETS (
        (s.s_store_name, rd.d_year),
        (s.s_store_name),
        (rd.d_year)
    )
ORDER BY
    total_profit DESC
LIMIT 100
