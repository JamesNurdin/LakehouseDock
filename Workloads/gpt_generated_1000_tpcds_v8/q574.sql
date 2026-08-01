WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
sales_join AS (
    SELECT
        cs.cs_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.cs_net_paid,
        cs.cs_order_number,
        p.p_promo_name,
        cp.cp_description,
        CASE
            WHEN cs.cs_net_paid > 1000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS spend_category
    FROM sampled_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '.*[0-9]{3}.*')
      AND p.p_channel_radio = 'Y'
      AND cp.cp_description LIKE '%NEW%'
),
sales_lateral AS (
    SELECT
        sj.cs_bill_customer_sk,
        sj.c_first_name,
        sj.c_last_name,
        sj.cs_net_paid,
        sj.spend_category,
        l.extract_num,
        CASE
            WHEN l.extract_num IS NULL THEN 'NO_NUM'
            ELSE 'HAS_NUM'
        END AS num_flag
    FROM sales_join sj
    CROSS JOIN LATERAL (
        SELECT regexp_extract(sj.cp_description, '(\\d{3})', 1) AS extract_num
    ) l
),
returns_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_return_amount > 0
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_returning_customer_sk
),
union_set AS (
    SELECT
        sl.cs_bill_customer_sk AS customer_sk,
        sl.c_first_name,
        sl.c_last_name,
        sl.cs_net_paid AS amount,
        sl.spend_category
    FROM sales_lateral sl
    UNION
    SELECT
        ra.customer_sk,
        c.c_first_name,
        c.c_last_name,
        -ra.total_return_amount AS amount,
        CASE WHEN ra.return_cnt > 5 THEN 'HIGH_RETURNS' ELSE 'LOW_RETURNS' END AS spend_category
    FROM returns_agg ra
    JOIN customer c
        ON ra.customer_sk = c.c_customer_sk
),
intersect_keys AS (
    SELECT customer_sk FROM union_set WHERE amount > 0
    INTERSECT
    SELECT cr_returning_customer_sk FROM catalog_returns WHERE cr_return_amount > 0
)
SELECT
    u.customer_sk,
    u.c_first_name,
    u.c_last_name,
    SUM(u.amount) AS net_amount,
    COUNT(*) AS record_cnt,
    MAX(u.spend_category) AS top_category
FROM union_set u
WHERE u.customer_sk IN (SELECT customer_sk FROM intersect_keys)
GROUP BY u.customer_sk, u.c_first_name, u.c_last_name
ORDER BY net_amount DESC
LIMIT 100
