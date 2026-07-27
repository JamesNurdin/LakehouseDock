WITH joined AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        ca.ca_state,
        cd.cd_gender,
        r.r_reason_desc,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        sr.sr_refunded_cash,
        wp.wp_type
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
)
,
unioned AS (
    SELECT
        c_customer_id,
        c_birth_year,
        SUM(ss_net_paid) AS total_sales,
        SUM(sr_refunded_cash) AS total_refund,
        COUNT(*) AS trans_cnt
    FROM joined
    WHERE ss_ext_sales_price > 1000
      AND c_birth_year = 1975
      AND ca_state = 'CA'
    GROUP BY c_customer_id, c_birth_year

    UNION ALL

    SELECT
        c_customer_id,
        c_birth_year,
        SUM(ss_net_paid) AS total_sales,
        SUM(sr_refunded_cash) AS total_refund,
        COUNT(*) AS trans_cnt
    FROM joined
    WHERE r_reason_desc = 'Wrong size'
      AND cd_gender = 'M'
      AND wp_type = 'product'
    GROUP BY c_customer_id, c_birth_year
)
SELECT
    c_customer_id,
    c_birth_year,
    SUM(total_sales) AS total_sales_sum,
    AVG(total_refund) AS avg_refund,
    COUNT(*) AS grp_cnt,
    MIN(total_sales) AS min_sales,
    MAX(total_sales) AS max_sales,
    SUM(SUM(total_sales)) OVER (PARTITION BY c_birth_year ORDER BY SUM(total_sales) DESC) AS running_total_by_birthyear
FROM unioned
GROUP BY c_customer_id, c_birth_year
ORDER BY total_sales_sum DESC
LIMIT 100
