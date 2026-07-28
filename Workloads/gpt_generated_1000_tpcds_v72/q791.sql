WITH store_state_sales AS (
    SELECT s.s_state AS state,
           SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_state
),
catalog_state_sales AS (
    SELECT cc.cc_state AS state,
           SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_state
),
combined AS (
    SELECT * FROM store_state_sales
    UNION ALL
    SELECT * FROM catalog_state_sales
)
SELECT
    state,
    total_sales,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100
