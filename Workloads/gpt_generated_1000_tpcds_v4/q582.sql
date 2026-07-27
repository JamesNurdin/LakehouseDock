WITH active_sales AS (
    SELECT
        ca.ca_state,
        'Active' AS promo_status,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_discount_active = 'Y'
      AND ss.ss_coupon_amt > 1000
      AND cd.cd_dep_employed_count >= 3
    GROUP BY ca.ca_state
),
inactive_sales AS (
    SELECT
        ca.ca_state,
        'Inactive' AS promo_status,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE p.p_discount_active = 'N'
      AND ss.ss_coupon_amt <= 1000
      AND cd.cd_dep_employed_count < 3
    GROUP BY ca.ca_state
),
combined AS (
    SELECT * FROM active_sales
    UNION ALL
    SELECT * FROM inactive_sales
)
SELECT
    combined.ca_state,
    combined.promo_status,
    combined.total_net_profit
FROM combined
ORDER BY combined.total_net_profit DESC
LIMIT 100
