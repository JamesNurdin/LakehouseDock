WITH catalog_agg AS (
    SELECT
        'catalog' AS src,
        cp.cp_type AS category,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_country = 'CHILE'
      AND cp.cp_catalog_page_number BETWEEN 5 AND 15
    GROUP BY cp.cp_type
),
store_agg AS (
    SELECT
        'store' AS src,
        CASE WHEN s.s_number_employees >= 250 THEN 'large' ELSE 'small' END AS category,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_country = 'CHILE'
    GROUP BY CASE WHEN s.s_number_employees >= 250 THEN 'large' ELSE 'small' END
)
SELECT src, category, total_net_loss
FROM catalog_agg
UNION ALL
SELECT src, category, total_net_loss
FROM store_agg
ORDER BY src, category
