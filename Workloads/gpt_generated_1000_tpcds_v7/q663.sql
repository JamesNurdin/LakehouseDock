WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_year,
        d.d_quarter_name,
        d.d_day_name,
        d.d_month_seq,
        d.d_date_id
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_day_name, '^[SM]')                 -- day names beginning with S or M (Sat, Sun, Mon)
      AND d.d_day_name LIKE '%day'                           -- all day names contain the word "day"
      AND regexp_extract(d.d_date_id, '(\\d{4})', 1) = CAST(d.d_year AS varchar)  -- year embedded in date_id matches d_year
      AND (d.d_day_name || '_' || CAST(d.d_month_seq AS varchar)) LIKE '%_1%'          -- month sequence contains a 1
)
SELECT
    d_year,
    d_quarter_name,
    COUNT(*) AS days_count,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_net_profit) AS avg_profit_per_day
FROM filtered_sales
GROUP BY d_year, d_quarter_name
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_profit DESC
LIMIT 20
