WITH high_link_pages AS (
    SELECT wp_web_page_sk,
           wp_url,
           wp_type,
           wp_link_count,
           wp_autogen_flag
    FROM web_page
    WHERE wp_link_count > (
        SELECT AVG(wp_link_count)
        FROM web_page
        WHERE wp_autogen_flag = 'N'
    )
)
SELECT
    cd.cd_gender,
    wp.wp_type,
    CONCAT(cd.cd_gender, '-', wp.wp_type) AS gender_type,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
FROM web_returns wr
JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN high_link_pages wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE REGEXP_LIKE(wp.wp_url, 'product.*\\.html$')
  AND wp.wp_type LIKE 'C%'
  AND cd.cd_demo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_dep_count > 2
          AND cd_purchase_estimate BETWEEN 3000 AND 8000
    )
GROUP BY
    cd.cd_gender,
    wp.wp_type,
    CONCAT(cd.cd_gender, '-', wp.wp_type),
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_net_loss DESC
LIMIT 100
