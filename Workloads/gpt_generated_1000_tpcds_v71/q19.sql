WITH sales_metrics AS (
    SELECT
        ca.ca_state AS state,
        'Sales' AS metric_type,
        SUM(ss.ss_ext_sales_price) AS metric_value,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS category
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1900
    GROUP BY ca.ca_state
),
discount_metrics AS (
    SELECT
        ca.ca_state AS state,
        'Discount' AS metric_type,
        SUM(ss.ss_ext_discount_amt) AS metric_value,
        CASE WHEN SUM(ss.ss_ext_discount_amt) > 10000 THEN 'HIGH' ELSE 'LOW' END AS category
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.date_dim d ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1900
      AND p.p_channel_email = 'Y'
    GROUP BY ca.ca_state
)
SELECT DISTINCT state, metric_type, metric_value, category
FROM (
    SELECT * FROM sales_metrics
    UNION ALL
    SELECT * FROM discount_metrics
) combined
ORDER BY state, metric_type
LIMIT 100
