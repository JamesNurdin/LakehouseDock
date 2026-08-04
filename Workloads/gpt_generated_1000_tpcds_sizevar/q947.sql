WITH
    -- Base data joining all three tables with selective filters
    base AS (
        SELECT
            ss.ss_customer_sk,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ss.ss_ext_tax,
            c.c_birth_country,
            cd.cd_gender,
            cd.cd_dep_college_count,
            CASE
                WHEN cd.cd_dep_college_count > 2 THEN 'HighCollegeDep'
                ELSE 'LowCollegeDep'
            END AS college_dep_category
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE c.c_birth_country = 'PHILIPPINES'
          AND ss.ss_ext_discount_amt > 1000
          AND cd.cd_gender = 'F'
    ),
    -- Scalar sub‑query returning a single value
    scalar_max_price AS (
        SELECT MAX(ss_ext_sales_price) AS max_price
        FROM store_sales
        WHERE ss_ext_tax < 200
    ),
    -- Subquery 1: customers with relatively high tax on sales
    sub_high_tax AS (
        SELECT ss_customer_sk, SUM(ss_ext_sales_price) AS total_sales
        FROM store_sales
        WHERE ss_ext_tax > 50
        GROUP BY ss_customer_sk
    ),
    -- Subquery 2: customers with low or zero tax on sales
    sub_low_tax AS (
        SELECT ss_customer_sk, SUM(ss_ext_sales_price) AS total_sales
        FROM store_sales
        WHERE ss_ext_tax <= 50
        GROUP BY ss_customer_sk
    ),
    -- INTERSECT of the two key sets
    intersect_set AS (
        SELECT ss_customer_sk FROM sub_high_tax
        INTERSECT
        SELECT ss_customer_sk FROM sub_low_tax
    ),
    -- UNION (distinct) of the two aggregated sets
    union_set AS (
        SELECT ss_customer_sk, total_sales FROM sub_high_tax
        UNION
        SELECT ss_customer_sk, total_sales FROM sub_low_tax
    )
SELECT
    b.c_birth_country,
    b.college_dep_category,
    COUNT(*) AS customer_count,
    SUM(b.ss_ext_sales_price) AS sum_sales,
    AVG(b.ss_net_profit) AS avg_profit,
    MAX(CASE WHEN b.ss_ext_tax > 200 THEN b.ss_ext_sales_price END) AS max_high_tax_sales,
    (SELECT max_price FROM scalar_max_price) AS overall_max_price
FROM base b
JOIN intersect_set i ON b.ss_customer_sk = i.ss_customer_sk
JOIN union_set u ON b.ss_customer_sk = u.ss_customer_sk
GROUP BY
    b.c_birth_country,
    b.college_dep_category
ORDER BY sum_sales DESC
LIMIT 100
