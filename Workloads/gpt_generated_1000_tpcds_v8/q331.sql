/* goal: Identify high‑value customers who have significant sales in both catalog and store channels, deduplicate overlapping records, and list the top customers by total net paid */
WITH cs_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
cs_join AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.cs_ext_list_price,
        cs.cs_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_ext_list_price DESC) AS rn
    FROM cs_sample cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_list_price > 2000
      AND NOT EXISTS (
          SELECT 1 FROM store_sales ss2 WHERE ss2.ss_customer_sk = c.c_customer_sk
      )
),
ss_join AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_ext_list_price,
        ss.ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_ext_list_price DESC) AS rn
    FROM ss_sample ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_ext_list_price > 2000
      AND NOT EXISTS (
          SELECT 1 FROM catalog_sales cs2 WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
      )
),
union_set AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cs_ext_list_price AS ext_list_price, cs_net_paid AS net_paid, rn
    FROM cs_join
    UNION
    SELECT c_customer_sk, c_first_name, c_last_name, ss_ext_list_price AS ext_list_price, ss_net_paid AS net_paid, rn
    FROM ss_join
),
intersect_set AS (
    SELECT c_customer_sk FROM cs_join
    INTERSECT
    SELECT c_customer_sk FROM ss_join
)
SELECT
    u.c_customer_sk,
    u.c_first_name,
    u.c_last_name,
    SUM(u.net_paid) AS total_net_paid,
    COUNT(*) AS sales_rows,
    MAX(u.ext_list_price) AS max_ext_list_price
FROM union_set u
JOIN intersect_set i
    ON u.c_customer_sk = i.c_customer_sk
GROUP BY u.c_customer_sk, u.c_first_name, u.c_last_name
HAVING SUM(u.net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
