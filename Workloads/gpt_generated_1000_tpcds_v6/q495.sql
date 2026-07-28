WITH recent_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
combined AS (
    SELECT
        s.s_store_id AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_profit) DESC) AS rank,
        'store' AS entity_type
    FROM store_sales ss
    JOIN recent_dates d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_email_address LIKE '%@%org'
    GROUP BY s.s_store_id, d.d_year

    UNION ALL

    SELECT
        cp.cp_catalog_page_id AS entity_id,
        d.d_year AS year,
        SUM(cs.cs_net_paid_inc_tax) AS net_paid,
        CAST(NULL AS decimal(7,2)) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS rank,
        'catalog' AS entity_type
    FROM catalog_sales cs
    JOIN recent_dates d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_catalog_page_id, d.d_year
)
SELECT
    entity_id,
    year,
    net_paid,
    net_profit,
    rank,
    entity_type
FROM combined
WHERE net_paid > (SELECT AVG(net_paid) FROM combined)
ORDER BY year DESC, net_paid DESC
LIMIT 100
