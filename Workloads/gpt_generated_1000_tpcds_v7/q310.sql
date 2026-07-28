WITH base AS (
    SELECT
        r.r_reason_desc,
        c.c_birth_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_birth_month IN (1, 2, 3, 4, 5, 6)
      AND sr.sr_return_amt > 100
      AND sr.sr_fee < 70
      AND wp.wp_rec_start_date >= DATE '2022-01-01'
      AND wp.wp_type = 'product'
    GROUP BY r.r_reason_desc, c.c_birth_year
)
SELECT
    r_reason_desc,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(returns_cnt) AS total_returns
FROM base
GROUP BY r_reason_desc
HAVING SUM(returns_cnt) > 10
ORDER BY avg_net_loss DESC
LIMIT 10
