WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
cs_agg AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           d.d_year,
           SUM(cs.cs_net_paid) AS total_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_bill_customer_sk, d.d_year
    HAVING SUM(cs.cs_net_paid) > 1000
),
ws_agg AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           d.d_year,
           SUM(ws.ws_net_paid) AS total_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_bill_customer_sk, d.d_year
    HAVING SUM(ws.ws_net_paid) > 1000
),
union_cust AS (
    SELECT cust_sk, d_year, total_paid FROM cs_agg
    UNION
    SELECT cust_sk, d_year, total_paid FROM ws_agg
),
intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM recent_dates)
),
cross_set AS (
    SELECT d.d_year,
           (SELECT AVG(cs.cs_net_paid)
            FROM catalog_sales cs
            WHERE cs.cs_sold_date_sk = d.d_date_sk) AS avg_paid
    FROM date_dim d
    WHERE d.d_year = 2001
)
SELECT
    u.cust_sk,
    u.d_year,
    u.total_paid,
    c.avg_paid,
    (SELECT MAX(cs_wholesale_cost) FROM catalog_sales) AS max_wholesale,
    CASE WHEN EXISTS (SELECT 1 FROM intersect_orders io WHERE io.order_number = u.cust_sk) THEN 1 ELSE 0 END AS intersect_flag
FROM union_cust u
CROSS JOIN cross_set c

UNION

SELECT
    TRY_CAST(w.web_site_id AS integer) AS cust_sk,
    d.d_year,
    SUM(ws.ws_net_paid) AS total_paid,
    NULL AS avg_paid,
    (SELECT MAX(cs_wholesale_cost) FROM catalog_sales) AS max_wholesale,
    0 AS intersect_flag
FROM web_sales ws
RIGHT OUTER JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
WHERE w.web_state = 'CA'
GROUP BY w.web_site_id, d.d_year
HAVING SUM(ws.ws_net_paid) > 500
ORDER BY cust_sk, d_year
LIMIT 100
