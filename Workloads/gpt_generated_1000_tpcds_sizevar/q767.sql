WITH sampled_catalog AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        CASE
            WHEN SUM(cs.cs_net_paid) > 100000 THEN 'Platinum'
            WHEN SUM(cs.cs_net_paid) > 50000  THEN 'Gold'
            ELSE 'Silver'
        END AS tier
    FROM sampled_catalog cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '.*[Bb]lue.*')
      AND cp.cp_type LIKE 'C%'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_returns AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(*) AS return_count,
        MAX(r.r_reason_desc) AS sample_reason
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damage%'
    GROUP BY sr.sr_customer_sk
),
intersect_items_per_customer AS (
    SELECT csd.c_customer_sk, sc.cs_item_sk AS item_sk
    FROM (
        SELECT cs.cs_item_sk, cs.cs_bill_customer_sk
        FROM sampled_catalog cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE regexp_like(cp.cp_description, '.*[Bb]lue.*')
    ) sc
    JOIN customer_sales csd ON sc.cs_bill_customer_sk = csd.c_customer_sk
    INTERSECT
    SELECT csd.c_customer_sk, ss.ss_item_sk
    FROM store_sales ss
    JOIN customer_sales csd ON ss.ss_customer_sk = csd.c_customer_sk
)
SELECT
    cs.c_customer_sk,
    concat(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.tier,
    cs.total_net_paid,
    cr.return_count,
    (SELECT COUNT(*) FROM store_returns sr_sub WHERE sr_sub.sr_customer_sk = cs.c_customer_sk) AS total_store_returns,
    CASE
        WHEN (SELECT COUNT(*) FROM store_returns sr_sub WHERE sr_sub.sr_customer_sk = cs.c_customer_sk) > 5 THEN 'Frequent'
        ELSE 'Occasional'
    END AS return_frequency,
    (SELECT COUNT(*) FROM intersect_items_per_customer ipc WHERE ipc.c_customer_sk = cs.c_customer_sk) AS common_item_count
FROM customer_sales cs
LEFT JOIN customer_returns cr ON cs.c_customer_sk = cr.sr_customer_sk
WHERE cs.total_net_paid > 0
ORDER BY cs.total_net_paid DESC
LIMIT 100
