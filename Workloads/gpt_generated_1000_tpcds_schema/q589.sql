WITH
    filtered_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cp.cp_catalog_page_sk,
            cp.cp_description,
            CASE
                WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
                WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
                ELSE 'LOW'
            END AS profit_category
        FROM catalog_sales cs
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE regexp_like(cp.cp_description, '(?i)exciting')
          AND cp.cp_description LIKE '%principles%'
    ),
    word_explode AS (
        SELECT
            fs.cs_order_number,
            word
        FROM filtered_sales fs
        CROSS JOIN UNNEST(split(fs.cp_description, ' ')) AS t(word)
        WHERE word <> ''
    ),
    returned_orders AS (
        SELECT DISTINCT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
    ),
    not_returned_orders AS (
        SELECT cs_order_number
        FROM filtered_sales
        EXCEPT
        SELECT cr_order_number FROM returned_orders
    ),
    anti_customers AS (
        SELECT *
        FROM customer
        WHERE c_customer_sk NOT IN (
            SELECT cr_refunded_customer_sk
            FROM catalog_returns
            WHERE cr_refunded_customer_sk IS NOT NULL
        )
          AND c_birth_country LIKE 'U%'
    ),
    sample_anti_customer AS (
        SELECT
            c.c_customer_sk,
            concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
            CASE WHEN c.c_birth_year < 1970 THEN 'Senior' ELSE 'Junior' END AS age_group
        FROM anti_customers c
        LIMIT 1
    ),
    store_agg AS (
        SELECT ss.ss_sold_date_sk,
            sum(ss.ss_net_paid) AS store_net_paid
        FROM store_sales ss
        GROUP BY ss.ss_sold_date_sk
    ),
    catalog_agg AS (
        SELECT fs.cs_sold_date_sk,
            sum(fs.cs_net_paid) AS catalog_net_paid,
            count(*) AS sales_cnt,
            sum(CASE WHEN fs.profit_category = 'HIGH' THEN 1 ELSE 0 END) AS high_profit_cnt
        FROM filtered_sales fs
        GROUP BY fs.cs_sold_date_sk
    ),
    full_join_agg AS (
        SELECT
            COALESCE(s.ss_sold_date_sk, c.cs_sold_date_sk) AS date_sk,
            s.store_net_paid,
            c.catalog_net_paid,
            c.sales_cnt,
            c.high_profit_cnt
        FROM store_agg s
        FULL OUTER JOIN catalog_agg c
            ON s.ss_sold_date_sk = c.cs_sold_date_sk
    )
SELECT
    fj.date_sk,
    fj.store_net_paid,
    fj.catalog_net_paid,
    fj.sales_cnt,
    fj.high_profit_cnt,
    (SELECT count(*) FROM not_returned_orders) AS not_returned_order_cnt,
    (SELECT count(*) FROM anti_customers) AS anti_customer_cnt,
    sac.full_name,
    sac.age_group,
    (SELECT word FROM word_explode LIMIT 1) AS sample_word
FROM full_join_agg fj
CROSS JOIN sample_anti_customer sac
WHERE fj.date_sk IS NOT NULL
ORDER BY fj.date_sk DESC
LIMIT 100
