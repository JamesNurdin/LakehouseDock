WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_zip,
        CONCAT(s.s_city, ', ', s.s_state) AS city_state,
        REGEXP_EXTRACT(s.s_zip, '(\\d+)', 1) AS zip_numeric,
        d.d_year,
        SUM(st.ss_net_paid) AS total_net_paid,
        SUM(st.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM
        store_sales st
        RIGHT OUTER JOIN store s
            ON st.ss_store_sk = s.s_store_sk
        LEFT JOIN date_dim d
            ON st.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN customer_demographics cd
            ON st.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        REGEXP_LIKE(s.s_hours, '^8AM-')
        AND s.s_zip LIKE '6%'
        AND (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_zip,
        d.d_year,
        CONCAT(s.s_city, ', ', s.s_state),
        REGEXP_EXTRACT(s.s_zip, '(\\d+)', 1)
    HAVING
        SUM(st.ss_net_profit) > 1000
)
SELECT
    sb.s_store_id,
    sb.city_state,
    sb.zip_numeric,
    sb.d_year,
    sb.total_net_paid,
    sb.total_profit,
    sb.sales_cnt
FROM
    sales_by_store sb
WHERE
    NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_store_sk = sb.s_store_sk
    )
ORDER BY
    sb.total_profit DESC
OFFSET 0
LIMIT 100
