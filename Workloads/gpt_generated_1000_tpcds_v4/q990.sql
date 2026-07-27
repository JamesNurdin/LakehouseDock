WITH sales_agg AS (
    SELECT
        ca.ca_state,
        c.c_birth_country,
        i.i_class,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        ca.ca_location_type = 'single family'
        AND c.c_birth_country IN ('MEXICO', 'FIJI', 'UKRAINE')
        AND i.i_units = 'Box'
        AND i.i_class_id IN (1, 3, 5)
        AND p.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_discount_active = 'Y'
        )
    GROUP BY ca.ca_state, c.c_birth_country, i.i_class, i.i_category
)
SELECT
    ca_state,
    c_birth_country,
    i_class,
    i_category,
    total_sales,
    total_profit,
    txn_count,
    total_profit / NULLIF(total_sales, 0) AS profit_margin,
    AVG(total_sales) OVER (PARTITION BY ca_state) AS avg_state_sales
FROM sales_agg
WHERE total_sales > 10000
ORDER BY total_profit DESC, total_sales DESC
LIMIT 100
