WITH cc_hours_exp AS (
    SELECT
        cc.cc_call_center_sk AS call_center_sk,
        cc.cc_name,
        split(cc.cc_hours, '-') AS hours_arr
    FROM call_center cc
    WHERE regexp_like(cc.cc_name, '^Call Center')
),
cc_hours_unnested AS (
    SELECT
        call_center_sk,
        cc_name,
        hour_part
    FROM cc_hours_exp
    CROSS JOIN UNNEST(hours_arr) AS t(hour_part)
),
store_monthly_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(s.s_store_name, '.*Store.*')
      AND s.s_state LIKE 'C%'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
    HAVING SUM(ss.ss_ext_sales_price) > 100000
),
avg_store_profit AS (
    SELECT AVG(total_net_profit) AS avg_profit
    FROM store_monthly_sales
),
high_profit_stores AS (
    SELECT
        s_store_sk,
        s_store_name,
        d_year,
        d_month_seq,
        total_net_profit,
        total_sales
    FROM store_monthly_sales
    WHERE total_net_profit > (SELECT avg_profit FROM avg_store_profit)
),
previous_year_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year AS d_year,
        d.d_month_seq,
        NULL AS total_net_profit,
        NULL AS total_sales,
        SUM(ss.ss_net_profit) AS prev_year_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
combined_sales AS (
    SELECT
        s_store_sk,
        s_store_name,
        d_year,
        d_month_seq,
        total_net_profit,
        total_sales,
        NULL AS prev_year_net_profit
    FROM high_profit_stores
    UNION ALL
    SELECT
        s_store_sk,
        s_store_name,
        d_year,
        d_month_seq,
        NULL AS total_net_profit,
        NULL AS total_sales,
        prev_year_net_profit
    FROM previous_year_sales
),
final AS (
    SELECT
        cs.s_store_sk,
        cs.s_store_name,
        cs.d_year,
        cs.d_month_seq,
        cs.total_net_profit,
        cs.total_sales,
        cs.prev_year_net_profit,
        substring(cs.s_store_name, 1, 3) AS store_prefix,
        regexp_extract(cs.s_store_name, '(Store)\\s+(.*)', 2) AS store_suffix,
        ch.hour_part
    FROM combined_sales cs
    LEFT JOIN cc_hours_unnested ch
        ON cs.s_store_name LIKE concat('%', ch.cc_name, '%')
    WHERE cs.total_net_profit IS NOT NULL
       OR cs.prev_year_net_profit IS NOT NULL
)
SELECT
    s_store_sk,
    s_store_name,
    d_year,
    d_month_seq,
    total_net_profit,
    total_sales,
    prev_year_net_profit,
    store_prefix,
    store_suffix,
    hour_part
FROM final
ORDER BY d_year DESC, d_month_seq ASC, total_net_profit DESC NULLS LAST
LIMIT 100
