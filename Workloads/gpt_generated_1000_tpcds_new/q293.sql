/*
  Goal: Compare total net paid (including shipping) and the number of sales per department for
        monthly catalog pages versus quarterly catalog pages. The first sub‑query filters sales to
        ship addresses that appear in an uncorrelated sub‑query of high‑value sales (> $5,000), while
        the second sub‑query uses a price range filter. Results from both sub‑queries are combined
        with UNION (distinct) to remove duplicate department‑type rows, then ordered and limited.
*/
WITH monthly_sales AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_type AS page_type,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND cs.cs_ship_addr_sk IN (
          SELECT DISTINCT cs2.cs_ship_addr_sk
          FROM catalog_sales cs2
          WHERE cs2.cs_net_paid_inc_ship > 5000
      )
    GROUP BY cp.cp_department, cp.cp_type
),
quarterly_sales AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_type AS page_type,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'quarterly'
      AND cs.cs_net_paid_inc_ship BETWEEN 3000 AND 8000
    GROUP BY cp.cp_department, cp.cp_type
)
SELECT
    department,
    page_type,
    total_net_paid,
    sales_cnt
FROM (
    SELECT department, page_type, total_net_paid, sales_cnt FROM monthly_sales
    UNION
    SELECT department, page_type, total_net_paid, sales_cnt FROM quarterly_sales
) AS combined
ORDER BY department ASC, total_net_paid DESC
LIMIT 100
