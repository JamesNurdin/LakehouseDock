WITH combined AS (
    -- Store sales segment focusing on blue items and zip codes starting with 75
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(*) AS txn_count,
        CASE WHEN ib.ib_upper_bound > 120000 THEN 'HighIncome' ELSE 'MidIncome' END AS income_category
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(i.i_item_desc, '(?i)blue')
      AND ca.ca_zip LIKE '75%'
    GROUP BY c.c_customer_sk, c.c_customer_id, ib.ib_upper_bound

    UNION ALL

    -- Catalog sales segment focusing on summer promotions and product codes "123"
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(*) AS txn_count,
        CASE WHEN ib.ib_upper_bound > 120000 THEN 'HighIncome' ELSE 'MidIncome' END AS income_category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_promo_name LIKE '%Summer%'
      AND regexp_extract(i.i_product_name, '(\\d{3})', 1) = '123'
    GROUP BY c.c_customer_sk, c.c_customer_id, ib.ib_upper_bound
)
SELECT
    combined.customer_id,
    SUM(combined.net_paid) AS total_net_paid,
    SUM(combined.txn_count) AS total_transactions,
    CASE WHEN SUM(combined.net_paid) > 5000 THEN 'HighSpender' ELSE 'Regular' END AS spender_category,
    MAX(combined.income_category) AS income_category
FROM combined
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss_ex
    JOIN promotion p_ex ON ss_ex.ss_promo_sk = p_ex.p_promo_sk
    WHERE ss_ex.ss_customer_sk = combined.customer_sk
      AND p_ex.p_promo_name LIKE '%Clearance%'
)
GROUP BY combined.customer_id
ORDER BY total_net_paid DESC
LIMIT 100
