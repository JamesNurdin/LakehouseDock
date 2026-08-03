WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_profit,
        d.d_date,
        d.d_day_name,
        t.t_meal_time,
        w.web_company_name,
        w.web_state,
        regexp_extract(w.web_company_name, '(\\w+)', 1) AS extracted_company,
        concat(w.web_company_name, ' ', w.web_state) AS company_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_day_name, '^S')               -- keep only Saturday or Sunday
      AND t.t_meal_time = 'dinner'                       -- dinner time sales
      AND w.web_company_name LIKE '%a%'                 -- company name contains the letter "a"
      AND regexp_like(w.web_company_name, '[A-Z][a-z]+')
)
SELECT
    d_date AS sale_date,
    substring(d_day_name, 1, 3) AS day_abbrev,
    company_state,
    extracted_company,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM sales_data
GROUP BY
    d_date,
    substring(d_day_name, 1, 3),
    company_state,
    extracted_company
ORDER BY total_profit DESC
LIMIT 100
