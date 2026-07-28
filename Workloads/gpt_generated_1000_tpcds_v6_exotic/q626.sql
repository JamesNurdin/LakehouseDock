WITH sales_agg AS (
    SELECT
        cust.c_customer_sk,
        ca.ca_state,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_refunds,
        SUM(COALESCE(cs.cs_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND ss.ss_customer_sk = cs.cs_bill_customer_sk
    WHERE ca.ca_state = 'TX'
      AND i.i_category = 'Electronics'
      AND cust.c_birth_year >= 1970
      AND ss.ss_quantity > 1
      AND (sr.sr_fee IS NULL OR sr.sr_fee < 50)
    GROUP BY cust.c_customer_sk, ca.ca_state, i.i_category
),
high_profit AS (
    SELECT
        c_customer_sk,
        total_sales,
        total_profit AS metric_value,
        'high_profit' AS metric_type
    FROM sales_agg
    WHERE total_profit > (SELECT AVG(total_profit) FROM sales_agg)
),
low_refund AS (
    SELECT
        c_customer_sk,
        total_sales,
        total_refunds AS metric_value,
        'low_refund' AS metric_type
    FROM sales_agg
    WHERE total_refunds < (SELECT AVG(total_refunds) FROM sales_agg)
)
SELECT
    c_customer_sk,
    total_sales,
    metric_value,
    metric_type
FROM high_profit
UNION ALL
SELECT
    c_customer_sk,
    total_sales,
    metric_value,
    metric_type
FROM low_refund
LIMIT 100
