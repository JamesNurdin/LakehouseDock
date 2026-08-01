/*
Goal: Identify high‑value web sales by meal time and sub‑shift, enrich with page domain information, filter by return reasons, and illustrate set‑operation analytics on order numbers while demonstrating string functions, a window ranking, and a right outer join to retain all time slots.
*/
WITH
-- Right outer join retains every time slot even if no sales exist
sales_right AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_web_page_sk,
        td.t_meal_time,
        td.t_sub_shift,
        ROW_NUMBER() OVER (PARTITION BY td.t_time_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn
    FROM web_sales ws
    RIGHT OUTER JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    -- scalar sub‑query comparison
    WHERE ws.ws_ext_sales_price > (SELECT MAX(ws2.ws_ext_sales_price) FROM web_sales ws2) / 2
),
-- Page information with regex extraction and concatenation
page_filtered AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        regexp_extract(wp.wp_url, '(https?://[^/]+)', 1) AS domain,
        concat('URL_', wp.wp_url) AS url_label
    FROM web_page wp
    WHERE wp.wp_url LIKE 'http%://%'
),
-- Returns with reason, using regex on the description
returns_with_reason AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        r.r_reason_desc,
        r.r_reason_id
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'defect')
),
-- Set operations on order numbers
union_orders AS (
    SELECT ws.ws_order_number AS order_id FROM web_sales ws WHERE ws.ws_ext_sales_price > 2000
    UNION ALL
    SELECT wr.wr_order_number FROM web_returns wr WHERE wr.wr_return_amt > 300
),
intersect_orders AS (
    SELECT ws.ws_order_number FROM web_sales ws
    INTERSECT
    SELECT wr.wr_order_number FROM web_returns wr
),
except_orders AS (
    SELECT ws.ws_order_number FROM web_sales ws
    EXCEPT
    SELECT wr.wr_order_number FROM web_returns wr
)
SELECT
    s.t_meal_time,
    s.t_sub_shift,
    COUNT(DISTINCT s.ws_order_number)                         AS distinct_orders,
    SUM(s.ws_ext_sales_price)                                 AS total_sales,
    AVG(s.ws_net_profit)                                      AS avg_profit,
    MAX(p.domain) FILTER (WHERE regexp_like(p.wp_url, '^https?://.*\\.com$')) AS top_com_domain,
    COUNT(DISTINCT u.order_id)                                AS union_order_count,
    COUNT(DISTINCT i.ws_order_number)                         AS intersect_order_count,
    COUNT(DISTINCT e.ws_order_number)                         AS except_order_count,
    ROW_NUMBER() OVER (ORDER BY SUM(s.ws_ext_sales_price) DESC) AS revenue_rank
FROM sales_right s
LEFT JOIN page_filtered p   ON s.ws_web_page_sk = p.wp_web_page_sk
LEFT JOIN returns_with_reason r ON s.ws_order_number = r.wr_order_number
JOIN union_orders u      ON s.ws_order_number = u.order_id
JOIN intersect_orders i  ON s.ws_order_number = i.ws_order_number
JOIN except_orders e     ON s.ws_order_number = e.ws_order_number
WHERE s.rn = 1
GROUP BY s.t_meal_time, s.t_sub_shift
ORDER BY total_sales DESC
LIMIT 100
