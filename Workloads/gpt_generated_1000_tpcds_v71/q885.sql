WITH sales AS (
    SELECT
        ss.ss_customer_sk,
        cd.cd_gender,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE
        regexp_like(c.c_email_address, '^.+@example\\.com$')
        AND c.c_preferred_cust_flag = 'Y'
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        ss.ss_customer_sk,
        cd.cd_gender,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)
)
SELECT
    s.ss_customer_sk,
    s.cd_gender,
    s.email_domain,
    s.total_profit,
    s.sales_cnt,
    CONCAT(s.cd_gender, '_', s.email_domain) AS gender_domain_key
FROM sales s
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returning_customer_sk = s.ss_customer_sk
      AND r.r_reason_desc LIKE '%not like the model%'
)
ORDER BY s.total_profit DESC
LIMIT 100
