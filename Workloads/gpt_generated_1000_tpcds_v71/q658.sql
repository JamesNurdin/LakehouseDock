WITH base_sales AS (
    SELECT
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ca.ca_state,
        p.p_promo_name,
        p.p_discount_active
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
aggregated AS (
    SELECT
        sub.state,
        sub.promo_name,
        SUM(sub.sales) AS total_sales,
        SUM(sub.profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM (
        SELECT
            bs.ca_state AS state,
            bs.p_promo_name AS promo_name,
            bs.ss_ext_sales_price AS sales,
            bs.ss_net_profit AS profit
        FROM base_sales bs
        WHERE bs.ca_state IN ('TN', 'CO')
          AND bs.p_discount_active = 'Y'
        UNION ALL
        SELECT
            bs.ca_state AS state,
            bs.p_promo_name AS promo_name,
            bs.ss_ext_sales_price AS sales,
            bs.ss_net_profit AS profit
        FROM base_sales bs
        WHERE bs.ca_state IN ('NM', 'AZ')
          AND bs.p_discount_active = 'N'
    ) sub
    GROUP BY sub.state, sub.promo_name
)
SELECT
    aggregated.state,
    aggregated.promo_name,
    aggregated.total_sales,
    aggregated.total_profit,
    aggregated.txn_count,
    ROW_NUMBER() OVER (PARTITION BY aggregated.state ORDER BY aggregated.total_sales DESC) AS rank_within_state
FROM aggregated
ORDER BY aggregated.total_sales DESC
LIMIT 100
