WITH wr_agg AS (
    SELECT
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_refunded_cdemo_sk,
        wr_returning_cdemo_sk,
        wr_web_page_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_quantity
    FROM web_returns
    GROUP BY
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_refunded_cdemo_sk,
        wr_returning_cdemo_sk,
        wr_web_page_sk
),
wp_agg AS (
    SELECT
        wp_web_page_sk,
        wp_creation_date_sk,
        wp_access_date_sk,
        ARRAY_AGG(wp_url) AS urls_arr,
        MAX(wp_max_ad_count) AS max_ad_count
    FROM web_page
    GROUP BY wp_web_page_sk, wp_creation_date_sk, wp_access_date_sk
)
SELECT
    d_ret.d_year,
    cd_ref.cd_gender,
    SUM(wr_agg.total_return_amt) AS sum_return_amt,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(wr_agg.total_return_amt) > (SELECT AVG(wr_return_amt) FROM web_returns) THEN 'HIGH'
        ELSE 'LOW'
    END AS return_level,
    url
FROM wr_agg
JOIN date_dim d_ret
    ON wr_agg.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON wr_agg.wr_returned_time_sk = t_ret.t_time_sk
JOIN customer_demographics cd_ref
    ON wr_agg.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr_agg.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_page wp1
    ON wr_agg.wr_web_page_sk = wp1.wp_web_page_sk
JOIN wp_agg wp2
    ON wp1.wp_web_page_sk = wp2.wp_web_page_sk
JOIN date_dim d_creation
    ON wp1.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp1.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_creation2
    ON wp2.wp_creation_date_sk = d_creation2.d_date_sk
LEFT JOIN UNNEST(wp2.urls_arr) AS u(url) ON TRUE
GROUP BY GROUPING SETS (
    (d_ret.d_year, cd_ref.cd_gender, url),
    (d_ret.d_year, url),
    (cd_ref.cd_gender, url),
    (url)
)
ORDER BY sum_return_amt DESC
LIMIT 100
