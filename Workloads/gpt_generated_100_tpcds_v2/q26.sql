WITH sales_web AS (
    SELECT
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        wp.wp_type,
        wp.wp_rec_start_date
    FROM catalog_sales cs
    JOIN web_page wp
        ON cs.cs_bill_customer_sk = wp.wp_customer_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
)
SELECT
    wp_type,
    DATE_TRUNC('month', wp_rec_start_date) AS month_start,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_coupon_amt) AS total_coupon_amount,
    COUNT(*) AS transaction_count
FROM sales_web
GROUP BY wp_type, DATE_TRUNC('month', wp_rec_start_date)
ORDER BY total_net_profit DESC
LIMIT 20
