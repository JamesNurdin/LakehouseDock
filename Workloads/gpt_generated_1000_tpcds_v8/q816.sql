WITH sales_demo AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_list_price,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        c.c_birth_year,
        c.c_preferred_cust_flag
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_ext_list_price > 1000                -- price predicate 1
      AND cd.cd_dep_count >= 2                       -- dep count predicate 2
      AND c.c_birth_year BETWEEN 1970 AND 1990      -- birth year predicate 3
      AND c.c_preferred_cust_flag = 'Y'             -- preferred flag predicate 4
      AND cd.cd_gender = 'M'                        -- gender predicate 5
),
agg_sales AS (
    SELECT
        sd.ss_customer_sk,
        COUNT(*) AS purchases,
        SUM(sd.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(sd.ss_ext_sales_price) > 5000 THEN 'HIGH' ELSE 'MEDIUM' END AS spend_category,
        ROW_NUMBER() OVER (ORDER BY SUM(sd.ss_ext_sales_price) DESC) AS sales_rank
    FROM sales_demo sd
    GROUP BY sd.ss_customer_sk
    HAVING COUNT(*) >= 2
),
full_demo AS (
    SELECT
        c.c_customer_sk,
        cd.cd_demo_sk,
        c.c_birth_year
    FROM customer c
    FULL OUTER JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    fd.c_customer_sk,
    ag.sales_rank,
    ag.total_sales,
    ag.spend_category,
    fd.c_birth_year
FROM full_demo fd
JOIN agg_sales ag
    ON fd.c_customer_sk = ag.ss_customer_sk
WHERE fd.c_customer_sk IN (
    SELECT sd.ss_customer_sk FROM sales_demo sd WHERE sd.ss_ext_sales_price > 2000
    INTERSECT
    SELECT sd.ss_customer_sk FROM sales_demo sd WHERE sd.cd_dep_employed_count > 3
    EXCEPT
    SELECT sd.ss_customer_sk FROM sales_demo sd WHERE sd.ss_ext_sales_price < 500
)
ORDER BY ag.sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
