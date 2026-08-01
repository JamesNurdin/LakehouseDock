/*
  Goal: Identify the most profitable brand‑category combinations per web site state, 
  including distinct item counts per site, while retaining all web sites (even those with no sales). 
  The query demonstrates complex analytics: right outer join, lateral subquery, CASE logic, 
  GROUP BY CUBE, window ranking, correlated subqueries, UNION DISTINCT and a final LIMIT.
*/
WITH base_sales AS (
    -- Join fact to dimensions, keep all web sites (right outer join)
    SELECT
        ws.ws_web_site_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_brand,
        i.i_category,
        s.web_state,
        s.web_tax_percentage,
        s.web_name
    FROM web_sales ws
    RIGHT OUTER JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    LEFT JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE
        s.web_tax_percentage >= 0.04               -- predicate 1
        AND s.web_state NOT IN ('FL')               -- predicate 2
        AND i.i_brand_id IN (3002001, 1002001, 6008007)  -- predicate 3
        AND ws.ws_quantity > 0                     -- predicate 4
),
-- Lateral subquery to count distinct items sold per site (uses DISTINCT inside)
items_per_site AS (
    SELECT
        b.ws_web_site_sk,
        di.distinct_item_cnt
    FROM base_sales b
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT ws_item_sk) AS distinct_item_cnt
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = b.ws_web_site_sk
    ) AS di
),
-- Aggregate with CUBE to get all‑dimension combinations
aggregated AS (
    SELECT
        b.web_state,
        b.i_brand,
        b.i_category,
        SUM(b.ws_ext_sales_price) AS total_sales,
        SUM(b.ws_net_profit) AS total_profit,
        CASE WHEN SUM(b.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        ips.distinct_item_cnt
    FROM base_sales b
    LEFT JOIN items_per_site ips
        ON b.ws_web_site_sk = ips.ws_web_site_sk
    GROUP BY CUBE (b.web_state, b.i_brand, b.i_category, ips.distinct_item_cnt)
    HAVING SUM(b.ws_ext_sales_price) IS NOT NULL
)
-- First part of the UNION: high‑sales profitable rows
SELECT
    a.web_state,
    a.i_brand,
    a.i_category,
    a.total_sales,
    a.total_profit,
    a.profit_flag,
    a.distinct_item_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.web_state ORDER BY a.total_sales DESC) AS rn_state,
    (
        SELECT AVG(ws_ext_sales_price)
        FROM web_sales ws_sub
        JOIN web_site s_sub ON ws_sub.ws_web_site_sk = s_sub.web_site_sk
        WHERE s_sub.web_state = a.web_state
    ) AS avg_state_sales
FROM aggregated a
WHERE a.total_sales > (
        SELECT AVG(ws_ext_sales_price)
        FROM web_sales ws_sub
        JOIN web_site s_sub ON ws_sub.ws_web_site_sk = s_sub.web_site_sk
        WHERE s_sub.web_state = a.web_state
    )
  AND a.profit_flag = 'Profit'
  AND a.distinct_item_cnt > 0
  AND a.i_category IS NOT NULL

UNION DISTINCT

-- Second part of the UNION: low‑sales loss rows (reverse ranking)
SELECT
    a.web_state,
    a.i_brand,
    a.i_category,
    a.total_sales,
    a.total_profit,
    a.profit_flag,
    a.distinct_item_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.web_state ORDER BY a.total_sales ASC) AS rn_state,
    (
        SELECT MIN(ws_ext_sales_price)
        FROM web_sales ws_sub
        JOIN web_site s_sub ON ws_sub.ws_web_site_sk = s_sub.web_site_sk
        WHERE s_sub.web_state = a.web_state
    ) AS min_state_sales
FROM aggregated a
WHERE a.total_sales <= (
        SELECT AVG(ws_ext_sales_price)
        FROM web_sales ws_sub
        JOIN web_site s_sub ON ws_sub.ws_web_site_sk = s_sub.web_site_sk
        WHERE s_sub.web_state = a.web_state
    )
  AND a.profit_flag = 'Loss'
  AND a.distinct_item_cnt IS NOT NULL
  AND a.i_category IS NOT NULL
LIMIT 100
