WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_manager,
        cc_street_name,
        cc_closed_date_sk,
        regexp_extract(cc_manager, '(\\w+) (\\w+)', 2) AS manager_last_name
    FROM call_center
    WHERE regexp_like(cc_manager, '^J')
      AND cc_street_name LIKE '%Sycamore%'
),
sales_with_date AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
    WHERE ss_ext_sales_price > 5000
),
joined_data AS (
    SELECT
        fcc.cc_manager,
        fcc.manager_last_name,
        d.d_day_name,
        d.d_weekend,
        s.ss_net_profit
    FROM filtered_cc fcc
    JOIN date_dim d ON fcc.cc_closed_date_sk = d.d_date_sk
    JOIN sales_with_date s ON d.d_date_sk = s.sold_date_sk
),
agg_weekend AS (
    SELECT
        jd.cc_manager AS manager,
        jd.manager_last_name,
        SUM(jd.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUBSTRING(jd.d_day_name, 1, 3) AS day_abbr
    FROM joined_data jd
    WHERE jd.d_weekend = 'Y'
    GROUP BY jd.cc_manager, jd.manager_last_name, jd.d_day_name
),
agg_start_s AS (
    SELECT
        jd.cc_manager AS manager,
        jd.manager_last_name,
        SUM(jd.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUBSTRING(jd.d_day_name, 1, 3) AS day_abbr
    FROM joined_data jd
    WHERE regexp_like(jd.d_day_name, '^S')
    GROUP BY jd.cc_manager, jd.manager_last_name, jd.d_day_name
),
combined AS (
    SELECT * FROM agg_weekend
    UNION ALL
    SELECT * FROM agg_start_s
)
SELECT
    manager,
    manager_last_name,
    total_profit,
    sales_cnt,
    day_abbr,
    ROW_NUMBER() OVER (PARTITION BY manager ORDER BY total_profit DESC) AS rn
FROM combined
ORDER BY manager, total_profit DESC
LIMIT 100
