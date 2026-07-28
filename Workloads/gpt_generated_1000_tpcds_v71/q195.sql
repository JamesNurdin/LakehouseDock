WITH
    store_ret AS (
        SELECT
            sr.sr_customer_sk,
            sr.sr_store_sk,
            sr.sr_reason_sk,
            SUM(sr.sr_return_amt) AS store_return_amt,
            COUNT(*) AS store_return_cnt
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 0
        GROUP BY sr.sr_customer_sk, sr.sr_store_sk, sr.sr_reason_sk
    ),
    web_ret AS (
        SELECT
            wr.wr_refunded_customer_sk AS customer_sk,
            wr.wr_reason_sk,
            SUM(wr.wr_return_amt) AS web_return_amt,
            COUNT(*) AS web_return_cnt
        FROM web_returns wr
        WHERE wr.wr_return_quantity > 0
          AND wr.wr_return_amt > 0
        GROUP BY wr.wr_refunded_customer_sk, wr.wr_reason_sk
    ),
    wp_agg AS (
        SELECT
            wp.wp_customer_sk,
            COUNT(*) AS page_count
        FROM web_page wp
        WHERE wp.wp_type = 'home'
        GROUP BY wp.wp_customer_sk
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    s.s_state,
    COALESCE(sr.store_return_amt, 0) + COALESCE(wr.web_return_amt, 0) AS total_return_amt,
    sr.store_return_amt,
    wr.web_return_amt,
    wp.page_count,
    RANK() OVER (
        PARTITION BY s.s_state
        ORDER BY (COALESCE(sr.store_return_amt, 0) + COALESCE(wr.web_return_amt, 0)) DESC
    ) AS state_rank,
    (SELECT MAX(ib_inner.ib_upper_bound) FROM income_band ib_inner) AS max_income_upper
FROM store_ret sr
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
JOIN customer c ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN web_ret wr ON wr.customer_sk = c.c_customer_sk
    AND wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN wp_agg wp ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
WHERE c.c_birth_country IN ('CAYMAN ISLANDS', 'FIJI')
  AND r.r_reason_desc LIKE '%price%'
  AND ib.ib_lower_bound >= 120000
  AND s.s_state = 'CA'
ORDER BY total_return_amt DESC
LIMIT 100
