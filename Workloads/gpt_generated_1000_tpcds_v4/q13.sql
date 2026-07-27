WITH sold_dates AS (
        SELECT d_date_sk,
               d_year,
               d_month_seq,
               d_qoy,
               d_holiday
        FROM date_dim
        WHERE d_year = 2001
          AND d_qoy = 2
    ),
    call_center_open AS (
        SELECT cc_call_center_sk,
               cc_name,
               cc_market_manager,
               cc_gmt_offset,
               cc_employees
        FROM call_center
        WHERE cc_employees > 100
    ),
    web_page_creation AS (
        SELECT wp_web_page_sk,
               wp_type,
               wp_char_count,
               wp_rec_end_date,
               wp_creation_date_sk
        FROM web_page
        WHERE wp_char_count BETWEEN 1000 AND 6000
          AND wp_rec_end_date = DATE '2001-09-02'
    )
SELECT
    cc.cc_name,
    ds.d_month_seq,
    wp.wp_type,
    COUNT(DISTINCT cs.cs_order_number)               AS order_cnt,
    SUM(cs.cs_ext_sales_price)                       AS total_ext_sales,
    AVG(cs.cs_net_paid_inc_ship)                     AS avg_net_paid_inc_ship,
    MIN(cs.cs_ext_discount_amt)                     AS min_discount,
    MAX(cs.cs_ext_discount_amt)                     AS max_discount
FROM catalog_sales cs
JOIN sold_dates ds
     ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN call_center_open cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_page_creation wp
     ON wp.wp_creation_date_sk = ds.d_date_sk
WHERE cs.cs_item_sk IN (189560, 145900)
  AND cs.cs_net_paid_inc_ship > 5000
GROUP BY cc.cc_name, ds.d_month_seq, wp.wp_type
ORDER BY total_ext_sales DESC
LIMIT 100
