WITH store_sales_2022 AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_hdemo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
)
SELECT
    s.s_store_id,
    s.s_city,
    regexp_extract(s.s_zip, '(\\d{3})', 1) AS zip_prefix,
    CASE
        WHEN s.s_number_employees > 250 THEN 'Large'
        WHEN s.s_number_employees BETWEEN 200 AND 250 THEN 'Medium'
        ELSE 'Small'
    END AS size_category,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2022
    ) AS overall_avg_net_profit,
    SUM(CASE WHEN regexp_like(s.s_city, '^A.*') THEN ss.ss_net_profit ELSE 0 END) AS profit_city_start_A
FROM store_sales_2022 ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE regexp_like(s.s_zip, '^\\d{5}$')
  AND s.s_state LIKE 'CA%'
  AND (s.s_city LIKE '%ville' OR s.s_city LIKE '%town')
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_store_sk = s.s_store_sk
    )
GROUP BY
    s.s_store_id,
    s.s_city,
    regexp_extract(s.s_zip, '(\\d{3})', 1),
    CASE
        WHEN s.s_number_employees > 250 THEN 'Large'
        WHEN s.s_number_employees BETWEEN 200 AND 250 THEN 'Medium'
        ELSE 'Small'
    END
HAVING COUNT(*) > 10
ORDER BY total_net_profit DESC
LIMIT 100
