WITH sales_by_store AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        MAX(d.d_date) AS last_sale_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk
)
SELECT
    st.s_store_name,
    st.s_city,
    st.s_state,
    st.s_suite_number,
    regexp_extract(st.s_suite_number, '[0-9]+') AS suite_number_digits,
    CONCAT(st.s_city, ', ', st.s_state) AS location,
    sb.total_sales,
    sb.total_profit,
    sb.sales_cnt,
    sb.last_sale_date
FROM store st
JOIN sales_by_store sb ON st.s_store_sk = sb.ss_store_sk
WHERE
    regexp_like(st.s_suite_number, '^Suite [0-9]+[A-Z]$')
    AND st.s_store_name LIKE '%Store%'
    AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE ss2.ss_store_sk = st.s_store_sk
          AND d2.d_weekend = 'Y'
    )
ORDER BY sb.total_sales DESC
LIMIT 100
