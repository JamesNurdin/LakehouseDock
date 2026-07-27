WITH sales AS (
    SELECT
        s.s_store_id,
        c.c_customer_id,
        cd.cd_gender,
        ib.ib_upper_bound,
        ss.ss_ext_sales_price AS amount,
        'sale' AS metric_type
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_ext_sales_price > 1500
      AND cd.cd_purchase_estimate >= 5000
      AND ib.ib_upper_bound <= 150000
),
returns AS (
    SELECT
        NULL AS s_store_id,
        c.c_customer_id,
        cd.cd_gender,
        ib.ib_upper_bound,
        wr.wr_return_amt AS amount,
        'return' AS metric_type
    FROM web_returns wr
    LEFT JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_return_amt > 200
      AND ib.ib_lower_bound >= 30000
      AND cd.cd_gender = 'F'
)
SELECT
    COALESCE(s_store_id, 'UNKNOWN') AS store_id,
    metric_type,
    COUNT(*) AS txn_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) u
WHERE amount IS NOT NULL
GROUP BY COALESCE(s_store_id, 'UNKNOWN'), metric_type
HAVING SUM(amount) > 5000
ORDER BY total_amount DESC
LIMIT 100
