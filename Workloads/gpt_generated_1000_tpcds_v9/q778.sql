WITH pre_sales AS (
    SELECT
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_ext_sales_price) AS total_sales_price,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales TABLESAMPLE BERNOULLI (5)
    GROUP BY ss_customer_sk, ss_cdemo_sk, ss_hdemo_sk
),
pre_returns AS (
    SELECT
        wr_refunded_customer_sk AS refunded_customer_sk,
        wr_refunded_cdemo_sk AS refunded_cdemo_sk,
        wr_refunded_hdemo_sk AS refunded_hdemo_sk,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns
    GROUP BY wr_refunded_customer_sk, wr_refunded_cdemo_sk, wr_refunded_hdemo_sk
)
SELECT
    ib_purch.ib_income_band_sk,
    MIN(ib_purch.ib_lower_bound) AS lower_bound,
    MAX(ib_purch.ib_upper_bound) AS upper_bound,
    cd_current.cd_gender,
    cd_current.cd_marital_status,
    SUM(s.total_sales_price) AS total_sales,
    SUM(s.total_net_paid) AS total_net_paid,
    SUM(s.total_discount) AS total_discount,
    COALESCE(SUM(r.total_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    SUM(s.total_sales_price) - COALESCE(SUM(r.total_return_amt), 0) AS net_revenue,
    CASE
        WHEN SUM(s.total_sales_price) - COALESCE(SUM(r.total_return_amt), 0) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS revenue_category
FROM pre_sales s
JOIN customer c_purch
    ON s.ss_customer_sk = c_purch.c_customer_sk
JOIN customer_demographics cd_purch
    ON s.ss_cdemo_sk = cd_purch.cd_demo_sk
JOIN household_demographics hd_purch
    ON s.ss_hdemo_sk = hd_purch.hd_demo_sk
JOIN customer_demographics cd_current
    ON c_purch.c_current_cdemo_sk = cd_current.cd_demo_sk
JOIN household_demographics hd_current
    ON c_purch.c_current_hdemo_sk = hd_current.hd_demo_sk
JOIN income_band ib_purch
    ON hd_purch.hd_income_band_sk = ib_purch.ib_income_band_sk
LEFT JOIN pre_returns r
    ON c_purch.c_customer_sk = r.refunded_customer_sk
LEFT JOIN customer c_refund
    ON r.refunded_customer_sk = c_refund.c_customer_sk
LEFT JOIN customer_demographics cd_refund
    ON r.refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund
    ON r.refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN income_band ib_refund
    ON hd_refund.hd_income_band_sk = ib_refund.ib_income_band_sk
GROUP BY ROLLUP (ib_purch.ib_income_band_sk, cd_current.cd_gender, cd_current.cd_marital_status)
ORDER BY net_revenue DESC
LIMIT 100
