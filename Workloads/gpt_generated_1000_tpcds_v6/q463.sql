WITH filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_web_page_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wp.wp_url,
        wp.wp_type,
        ca.ca_city,
        ca.ca_state,
        ca.ca_street_type,
        cd.cd_gender,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        t.t_sub_shift,
        regexp_extract(wp.wp_url, '/product/([0-9]+)', 1) AS product_id
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND ca.ca_street_type LIKE '%Ave%'
      AND regexp_like(wp.wp_url, '^/product/[0-9]+')
)
SELECT
    fr.d_year,
    fr.d_month_seq,
    fr.wp_type,
    CONCAT(fr.ca_city, ', ', fr.ca_state) AS location,
    fr.product_id,
    SUM(fr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count,
    AVG(fr.wr_return_tax) AS avg_return_tax,
    MIN(fr.wr_return_quantity) AS min_quantity,
    SUBSTRING(fr.wp_url, 1, 30) AS url_prefix
FROM filtered_returns fr
GROUP BY
    fr.d_year,
    fr.d_month_seq,
    fr.wp_type,
    fr.ca_city,
    fr.ca_state,
    fr.product_id,
    fr.wp_url
ORDER BY total_return_amount DESC, fr.d_year ASC
LIMIT 100
