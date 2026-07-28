WITH store_rev AS (
    SELECT
        'store' AS channel,
        s.s_store_name AS location,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_company_name = 'Unknown'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_name
),
catalog_rev AS (
    SELECT
        'catalog' AS channel,
        cp.cp_catalog_page_id AS location,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_type = 'PROMO'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cp.cp_catalog_page_id
)
SELECT *
FROM store_rev
UNION ALL
SELECT *
FROM catalog_rev
ORDER BY total_net_paid DESC
LIMIT 100
