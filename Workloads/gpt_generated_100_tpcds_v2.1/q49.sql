WITH sales_agg AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_txn_count
    FROM store_sales
    WHERE ss_quantity > 2
    GROUP BY ss_customer_sk
),
returns_agg AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_fee) AS total_fee,
        SUM(cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_txn_count
    FROM catalog_returns
    WHERE cr_fee > 20
      AND cr_ship_mode_sk IN (1, 9, 12)
    GROUP BY cr_refunded_customer_sk
),
customer_detail AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        ca.ca_state,
        sa.total_net_paid,
        sa.total_net_profit,
        ra.total_return_amount,
        ra.total_fee,
        (sa.total_net_profit - COALESCE(ra.total_return_amount, 0)) AS net_profit_after_returns,
        (sa.total_net_paid - COALESCE(ra.total_return_amount, 0) - COALESCE(ra.total_fee, 0)) AS net_revenue_after_returns
    FROM sales_agg sa
    JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
    LEFT JOIN returns_agg ra ON c.c_customer_sk = ra.customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_country IN ('UKRAINE', 'SWITZERLAND')
      AND ca.ca_state = 'CA'
)
SELECT
    cd.c_birth_country,
    COUNT(*) AS customer_count,
    AVG(cd.net_profit_after_returns) AS avg_net_profit,
    SUM(cd.net_revenue_after_returns) AS total_net_revenue
FROM customer_detail cd
GROUP BY cd.c_birth_country
HAVING COUNT(*) >= 5
ORDER BY avg_net_profit DESC
LIMIT 100
