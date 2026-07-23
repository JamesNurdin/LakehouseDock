WITH customer_sales AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_orders,
        SUM(cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
), customer_returns AS (
    SELECT
        sr_customer_sk AS customer_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_orders,
        COUNT(DISTINCT sr_reason_sk) AS distinct_return_reasons
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    substr(regexp_extract(c.c_email_address, '@(.+)$', 1), 1, 3) AS domain_prefix,
    cs.total_net_profit,
    cr.total_net_loss,
    CASE
        WHEN cs.total_net_profit > 10000 THEN 'High'
        WHEN cs.total_net_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    CASE
        WHEN cs.total_net_profit > 0 THEN round(cr.total_net_loss / cs.total_net_profit, 4)
        ELSE NULL
    END AS loss_to_profit_ratio,
    (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND EXISTS (
                SELECT 1
                FROM reason r2
                WHERE r2.r_reason_sk = sr2.sr_reason_sk
                  AND regexp_like(r2.r_reason_desc, '(?i)defect|damage')
          )
    ) AS defective_return_count
FROM customer c
INNER JOIN customer_sales cs ON cs.customer_sk = c.c_customer_sk
INNER JOIN customer_returns cr ON cr.customer_sk = c.c_customer_sk
WHERE (c.c_email_address LIKE '%@%.com' OR c.c_email_address LIKE '%@%.org')
  AND c.c_customer_id LIKE 'AAAAAAA%'
ORDER BY cs.total_net_profit DESC
LIMIT 100
