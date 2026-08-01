WITH
    -- Sample a fraction of store returns to reduce data volume
    sampled_store_returns AS (
        SELECT *
        FROM store_returns TABLESAMPLE BERNOULLI (10)
    ),

    -- Join customers with the sampled store returns and stores, applying several filters
    customer_store AS (
        SELECT
            c.c_customer_sk,
            c.c_birth_day,
            c.c_first_sales_date_sk,
            s.s_store_sk,
            sr.sr_return_amt,
            sr.sr_return_tax,
            sr.sr_store_credit
        FROM customer c
        JOIN sampled_store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        WHERE c.c_birth_day = 19
          AND sr.sr_return_tax > 2
    ),

    -- Catalog returns linked to the same customers and catalog pages, with filters
    catalog_part AS (
        SELECT
            c.c_customer_sk,
            cp.cp_catalog_page_sk,
            cp.cp_type,
            cr.cr_return_amount,
            cr.cr_return_quantity
        FROM customer c
        JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_type = 'monthly'
          AND cr.cr_return_amount > 100
    ),

    -- Web returns linked to the same customers, with filters
    web_part AS (
        SELECT
            c.c_customer_sk,
            wr.wr_return_amt,
            wr.wr_return_quantity
        FROM customer c
        JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        WHERE wr.wr_return_amt BETWEEN 0 AND 300
    ),

    -- Keep only customers that appear in both the store and web return slices
    intersect_customers AS (
        SELECT c.c_customer_sk
        FROM customer_store c
        INTERSECT
        SELECT w.c_customer_sk
        FROM web_part w
    ),

    -- Aggregate per customer, applying an anti‑join to exclude very large catalog returns
    agg_per_customer AS (
        SELECT
            cs.c_customer_sk,
            SUM(cs.sr_return_amt)          AS store_return_total,
            SUM(cp.cr_return_amount)       AS catalog_return_total,
            SUM(wp.wr_return_amt)          AS web_return_total,
            COUNT(DISTINCT cs.s_store_sk)   AS store_count
        FROM customer_store cs
        JOIN catalog_part cp   ON cp.c_customer_sk = cs.c_customer_sk
        JOIN web_part     wp   ON wp.c_customer_sk = cs.c_customer_sk
        WHERE cs.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
          AND NOT EXISTS (
                SELECT 1
                FROM catalog_returns cr2
                WHERE cr2.cr_refunded_customer_sk = cs.c_customer_sk
                  AND cr2.cr_return_amount > 1000
          )
        GROUP BY cs.c_customer_sk
    ),

    -- Separate high‑ and low‑store‑return groups and combine them with UNION DISTINCT
    high_low AS (
        SELECT
            'high' AS category,
            AVG(store_return_total)   AS avg_store_return,
            AVG(catalog_return_total) AS avg_catalog_return,
            AVG(web_return_total)     AS avg_web_return
        FROM agg_per_customer
        WHERE store_return_total > 500
        UNION DISTINCT
        SELECT
            'low' AS category,
            AVG(store_return_total)   AS avg_store_return,
            AVG(catalog_return_total) AS avg_catalog_return,
            AVG(web_return_total)     AS avg_web_return
        FROM agg_per_customer
        WHERE store_return_total <= 500
    )
SELECT
    category,
    avg_store_return,
    avg_catalog_return,
    avg_web_return
FROM high_low
ORDER BY category
LIMIT 100
