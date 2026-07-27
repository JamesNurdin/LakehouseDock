WITH base AS (
    SELECT
        d.d_year AS return_year,
        i.i_item_id,
        i.i_product_name,
        cd_ref.cd_gender,
        cd_ref.cd_marital_status,
        r.r_reason_desc AS reason_desc,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_quantity,
        COUNT(*) AS return_cnt,
        MIN(d.d_date) AS first_return_date,
        MAX(d.d_date) AS last_return_date
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d.d_year BETWEEN 1910 AND 1915
      AND t.t_am_pm = 'PM'
      AND i.i_brand = 'Brand#23'
      AND cd_ref.cd_gender = 'M'
      AND wp.wp_type = 'Content'
    GROUP BY
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        cd_ref.cd_gender,
        cd_ref.cd_marital_status,
        r.r_reason_desc,
        wp.wp_type
)
SELECT
    return_year,
    i_item_id,
    i_product_name,
    cd_gender,
    cd_marital_status,
    reason_desc,
    wp_type,
    total_return_amt,
    total_quantity,
    return_cnt,
    first_return_date,
    last_return_date,
    RANK() OVER (PARTITION BY return_year ORDER BY total_return_amt DESC) AS amt_rank,
    SUM(total_return_amt) OVER (PARTITION BY return_year ORDER BY total_return_amt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt
FROM base
ORDER BY return_year DESC, amt_rank
LIMIT 100
