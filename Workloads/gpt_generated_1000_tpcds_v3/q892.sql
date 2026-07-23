WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_sales_price) AS max_sales_price
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_sold_time_sk, ss.ss_hdemo_sk
),
cr_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returned_time_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        MIN(cp.cp_department) AS department,
        MIN(r_cr.r_reason_desc) AS return_reason_desc
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
    GROUP BY cr.cr_item_sk, cr.cr_returned_time_sk
),
wr_agg AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_time_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        MIN(wp.wp_type) AS web_page_type,
        MIN(wp.wp_autogen_flag) AS wp_autogen_flag,
        MIN(wp.wp_char_count) AS wp_char_count,
        MIN(r_wr.r_reason_desc) AS web_return_reason_desc
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
    GROUP BY wr.wr_item_sk, wr.wr_returned_time_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cr_agg.department,
    wr_agg.web_page_type,
    t.t_hour,
    hd_ss.hd_vehicle_count,
    SUM(ss_agg.total_sales_amount) AS sum_total_sales_amount,
    SUM(ss_agg.sales_transactions) AS sum_sales_transactions,
    AVG(ss_agg.avg_sales_price) AS avg_sales_price,
    MIN(ss_agg.min_sales_price) AS min_sales_price,
    MAX(ss_agg.max_sales_price) AS max_sales_price,
    COALESCE(SUM(cr_agg.total_return_amount), 0) AS sum_catalog_return_amount,
    COALESCE(SUM(wr_agg.total_web_return_amount), 0) AS sum_web_return_amount,
    (SELECT MAX(wr2.wr_return_amt) FROM web_returns wr2 WHERE wr2.wr_item_sk = i.i_item_sk) AS max_web_return_amt
FROM ss_agg
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN time_dim t ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd_ss ON ss_agg.ss_hdemo_sk = hd_ss.hd_demo_sk
LEFT JOIN cr_agg ON cr_agg.cr_item_sk = i.i_item_sk AND cr_agg.cr_returned_time_sk = t.t_time_sk
LEFT JOIN wr_agg ON wr_agg.wr_item_sk = i.i_item_sk AND wr_agg.wr_returned_time_sk = t.t_time_sk
WHERE
    i.i_current_price > 50.00
    AND t.t_hour BETWEEN 9 AND 17
    AND hd_ss.hd_vehicle_count >= 1
    AND cr_agg.department = 'Electronics'
    AND wr_agg.wp_autogen_flag = 'N'
    AND wr_agg.wp_char_count > 3000
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cr_agg.department,
    wr_agg.web_page_type,
    t.t_hour,
    hd_ss.hd_vehicle_count,
    i.i_item_sk
ORDER BY sum_total_sales_amount DESC
LIMIT 100
