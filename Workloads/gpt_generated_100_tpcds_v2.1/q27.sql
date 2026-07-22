WITH cust_store_agg AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS store_return_cnt,
        SUM(sr_return_amt) AS store_return_total,
        MAX(sr_return_amt) AS store_return_max
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_customer_sk
),
cust_web_agg AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        COUNT(*) AS web_return_cnt,
        SUM(wr_return_amt) AS web_return_total,
        MAX(wr_return_amt) AS web_return_max
    FROM web_returns
    WHERE wr_return_amt > 0
    GROUP BY wr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_dep_count,
    r.r_reason_desc,
    cs.store_return_total,
    cw.web_return_total,
    (cs.store_return_total + cw.web_return_total) AS total_return_amount,
    RANK() OVER (
        PARTITION BY cd.cd_gender
        ORDER BY (cs.store_return_total + cw.web_return_total) DESC
    ) AS gender_return_rank,
    ROW_NUMBER() OVER (
        ORDER BY (cs.store_return_total + cw.web_return_total) DESC
    ) AS overall_return_rank,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_quantity > 1
    ) AS high_value_store_return_cnt
FROM customer c
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN cust_store_agg cs
    ON cs.sr_customer_sk = c.c_customer_sk
JOIN cust_web_agg cw
    ON cw.customer_sk = c.c_customer_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    c.c_preferred_cust_flag = 'Y'
    AND cd.cd_gender = 'F'
    AND cd.cd_dep_count >= 2
    AND cs.store_return_total > 10
    AND cw.web_return_total > 5
    AND wp.wp_type = 'content'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = c.c_customer_sk
          AND sr3.sr_return_quantity > 1
    )
ORDER BY total_return_amount DESC
LIMIT 100
