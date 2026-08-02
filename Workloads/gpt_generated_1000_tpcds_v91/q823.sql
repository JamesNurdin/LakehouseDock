WITH wp_agg AS (
   SELECT
       wp.wp_web_page_sk,
       wp.wp_url,
       wp.wp_type,
       wp.wp_creation_date_sk,
       wp.wp_access_date_sk,
       d_create.d_year AS creation_year,
       d_create.d_month_seq AS creation_month_seq,
       d_access.d_year AS access_year,
       d_access.d_month_seq AS access_month_seq
   FROM web_page wp
   JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
   JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
)
SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(DISTINCT cr.cr_return_amount) AS distinct_return_amount_sum,
    AVG(DISTINCT cr.cr_return_quantity) AS avg_distinct_return_qty,
    COALESCE(wp_info.wp_type, 'UNKNOWN') AS page_type,
    COUNT(DISTINCT wp_info.wp_web_page_sk) AS distinct_pages
FROM catalog_returns cr
INNER JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk               -- join 1
INNER JOIN date_dim d_cre
        ON cr.cr_returned_date_sk = d_cre.d_date_sk               -- join 2 (second alias of date_dim)
INNER JOIN date_dim d_acc
        ON cr.cr_returned_date_sk = d_acc.d_date_sk               -- join 3 (third alias of date_dim)
INNER JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk               -- join 4
INNER JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk           -- join 5
INNER JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk          -- join 6
LEFT JOIN wp_agg wp_info
        ON d_ret.d_date_sk = wp_info.wp_creation_date_sk          -- join 7 (LEFT OUTER JOIN)
LEFT JOIN date_dim d_wp_create
        ON wp_info.wp_creation_date_sk = d_wp_create.d_date_sk    -- join 8
LEFT JOIN date_dim d_wp_access
        ON wp_info.wp_access_date_sk = d_wp_access.d_date_sk      -- join 9
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    cd_ret.cd_gender,
    cd_ret.cd_marital_status,
    wp_info.wp_type
HAVING COUNT(DISTINCT cr.cr_order_number) > 5
ORDER BY distinct_orders DESC
LIMIT 100
