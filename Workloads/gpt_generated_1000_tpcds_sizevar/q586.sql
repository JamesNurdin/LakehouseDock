WITH base_union AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wp.wp_max_ad_count >= 2
    GROUP BY CUBE (cd.cd_gender, cd.cd_marital_status, wp.wp_type)

    UNION

    SELECT
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_max_ad_count <= 2
    GROUP BY CUBE (cd.cd_gender, cd.cd_marital_status, wp.wp_type)
)
SELECT
    gender,
    marital_status,
    wp_type,
    total_return_amt,
    return_cnt,
    LAG(total_return_amt) OVER (PARTITION BY gender ORDER BY total_return_amt DESC) AS lag_total_return_amt,
    SUM(total_return_amt) OVER (PARTITION BY gender ORDER BY total_return_amt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return_amt
FROM base_union
ORDER BY gender NULLS LAST, total_return_amt DESC
LIMIT 100
