WITH customer_activity AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(*) FILTER (WHERE ss.ss_net_profit > 0) AS positive_txns,
        COUNT(*) FILTER (WHERE ss.ss_net_profit < 0) AS negative_txns,
        SUM(ss.ss_net_profit) AS net_profit,
        MAX(ss.ss_sold_date_sk) AS last_purchase_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
recent_promo AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM store_sales ss
    WHERE ss.ss_promo_sk IS NOT NULL
)
SELECT
    ca.c_customer_sk,
    ca.c_first_name,
    ca.c_last_name,
    ca.positive_txns,
    ca.negative_txns,
    ca.net_profit,
    p.p_promo_name,
    CASE WHEN ca.net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS overall_status,
    DENSE_RANK() OVER (ORDER BY ca.net_profit DESC) AS profit_dense_rank
FROM customer_activity ca
LEFT JOIN recent_promo rp ON ca.c_customer_sk = rp.ss_customer_sk AND rp.rn = 1
LEFT JOIN promotion p ON rp.ss_promo_sk = p.p_promo_sk
ORDER BY profit_dense_rank
LIMIT 15
