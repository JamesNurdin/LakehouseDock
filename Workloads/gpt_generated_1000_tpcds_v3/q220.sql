WITH sales_base AS (
    SELECT
        cust.c_customer_sk,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    sb.ib_lower_bound,
    sb.ib_upper_bound,
    sb.cd_gender,
    COUNT(DISTINCT sb.c_customer_sk) AS distinct_customers,
    SUM(sb.ss_net_paid) AS total_sales_net_paid,
    SUM(wr.wr_net_loss) AS total_returns_net_loss,
    AVG(sb.ss_ext_discount_amt) AS avg_discount_sales,
    (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2) AS avg_discount_all_sales,
    SUM(sb.ss_net_paid) / NULLIF(SUM(wr.wr_net_loss), 0) AS sales_to_returns_ratio
FROM sales_base sb
JOIN web_returns wr ON wr.wr_returning_customer_sk = sb.c_customer_sk
JOIN customer cust_ref ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_returning_customer_sk = sb.c_customer_sk
      AND wr2.wr_return_quantity > 0
)
GROUP BY
    sb.ib_lower_bound,
    sb.ib_upper_bound,
    sb.cd_gender
ORDER BY total_sales_net_paid DESC
LIMIT 100
