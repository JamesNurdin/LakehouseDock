WITH cs_keys AS (
    SELECT cs.cs_order_number AS order_key
    FROM tpcds.catalog_sales cs
    RIGHT OUTER JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour = 10
),
wr_keys AS (
    SELECT wr.wr_order_number AS order_key
    FROM tpcds.web_returns wr
    JOIN tpcds.time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    WHERE td2.t_hour = 10
),
union_keys AS (
    SELECT order_key FROM cs_keys
    UNION ALL
    SELECT order_key FROM wr_keys
),
ss_keys AS (
    SELECT ss.ss_ticket_number AS order_key
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim td3 ON ss.ss_sold_time_sk = td3.t_time_sk
    WHERE td3.t_hour = 10
),
cr_keys AS (
    SELECT cr.cr_order_number AS order_key
    FROM tpcds.catalog_returns cr
    JOIN tpcds.time_dim td4 ON cr.cr_returned_time_sk = td4.t_time_sk
    WHERE td4.t_hour = 10
),
-- intersect the union set with store‑sales keys, then remove any catalog‑return keys
final_keys AS (
    SELECT order_key FROM union_keys
    INTERSECT
    SELECT order_key FROM ss_keys
    EXCEPT
    SELECT order_key FROM cr_keys
)
SELECT
    CASE WHEN order_key % 2 = 0 THEN 'EVEN' ELSE 'ODD' END AS parity,
    order_key,
    (SELECT COUNT(*) FROM tpcds.customer) AS total_customers
FROM final_keys
ORDER BY order_key ASC
OFFSET 10 ROWS
LIMIT 100
