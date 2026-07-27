WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           c.c_birth_year,
           c.c_current_cdemo_sk
    FROM tpcds.customer c
    WHERE c.c_birth_year = 1975
)
SELECT
    s.s_store_name,
    cd.cd_gender,
    COUNT(DISTINCT ss.ss_ticket_number)                AS cnt_transactions,
    SUM(ss.ss_net_paid)                               AS total_sales,
    SUM(wr.wr_return_amt)                             AS total_returns,
    AVG(ss.ss_ext_discount_amt)                      AS avg_discount,
    MIN(ss.ss_sold_date_sk)                           AS first_sale_date_sk
FROM filtered_customers c
JOIN tpcds.customer_demographics cd
     ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.store_sales ss
     ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.store s
     ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.web_returns wr
     ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.reason r
     ON wr.wr_reason_sk = r.r_reason_sk
WHERE s.s_zip = '29584'
  AND s.s_rec_start_date >= DATE '2000-01-01'
  AND r.r_reason_desc = 'Damaged'
  AND wp.wp_max_ad_count >= 2
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
          AND wr2.wr_return_amt > 100
      )
GROUP BY s.s_store_name, cd.cd_gender
ORDER BY total_sales DESC
LIMIT 100
