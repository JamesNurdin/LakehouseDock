WITH sales_by_date AS (
    SELECT
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_sales_price > 100
    GROUP BY ss_sold_date_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
    dd.d_date AS closed_date,
    sb.total_sales,
    sb.total_profit,
    sb.sales_cnt,
    REGEXP_EXTRACT(cc.cc_name, '(.*) Center', 1) AS name_prefix,
    CASE
        WHEN REGEXP_LIKE(cc.cc_manager, '^.*[A-Z]{2}.*$') THEN 'HasTwoUpper'
        ELSE 'Other'
    END AS manager_code
FROM call_center cc
JOIN date_dim dd ON cc.cc_closed_date_sk = dd.d_date_sk
LEFT JOIN sales_by_date sb ON sb.ss_sold_date_sk = cc.cc_closed_date_sk
WHERE
    REGEXP_LIKE(cc.cc_name, '^.*Center$')
    AND dd.d_day_name LIKE 'Sat%'
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returned_date_sk = cc.cc_closed_date_sk
    )
ORDER BY sb.total_sales DESC
LIMIT 100
