WITH catalog_agg AS (
    SELECT d.d_date AS the_date,
           cp.cp_department AS department,
           SUM(cs.cs_net_paid) AS net_paid
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (5)
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND cp.cp_department IN ('Books', 'Electronics')
      AND hd.hd_buy_potential = 'High'
    GROUP BY d.d_date, cp.cp_department
),
web_agg AS (
    SELECT d.d_date AS the_date,
           wp.wp_type AS page_type,
           COUNT(*) AS page_accesses
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND wp.wp_type IN ('Product', 'Category')
    GROUP BY d.d_date, wp.wp_type
),
union_agg AS (
    SELECT 'catalog' AS source,
           the_date,
           CONCAT('net_paid_', department) AS metric_name,
           CAST(net_paid AS double) AS metric_value
    FROM catalog_agg
    UNION ALL
    SELECT 'web' AS source,
           the_date,
           CONCAT('page_accesses_', page_type) AS metric_name,
           CAST(page_accesses AS double) AS metric_value
    FROM web_agg
)
SELECT ua.source,
       ua.the_date,
       ua.metric_name,
       ua.metric_value,
       ua.metric_value > (
           SELECT AVG(ua2.metric_value)
           FROM union_agg ua2
           WHERE ua2.the_date = ua.the_date
             AND ua2.source = ua.source
       ) AS above_average
FROM union_agg ua
ORDER BY ua.metric_value DESC
LIMIT 100
