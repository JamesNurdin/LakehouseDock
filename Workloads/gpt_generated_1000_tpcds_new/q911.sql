WITH
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_with_adjusted AS (
        SELECT
            s.s_store_id,
            c.c_email_address,
            ss.ss_ext_sales_price,
            ss.ss_coupon_amt,
            la.adjusted_price
        FROM sampled_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        CROSS JOIN LATERAL (
            SELECT ss.ss_ext_sales_price - ss.ss_coupon_amt AS adjusted_price
        ) la
        WHERE s.s_manager = 'John Mccoy'
          AND ss.ss_ext_sales_price > 500
    ),
    other_sales AS (
        SELECT
            s.s_store_id,
            NULL AS c_email_address,
            ss.ss_ext_sales_price,
            ss.ss_coupon_amt,
            la.adjusted_price
        FROM sampled_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        CROSS JOIN LATERAL (
            SELECT ss.ss_ext_sales_price - ss.ss_coupon_amt AS adjusted_price
        ) la
        WHERE s.s_manager = 'Edwin Adams'
          AND ss.ss_ext_sales_price < 200
    ),
    unioned_sales AS (
        SELECT * FROM sales_with_adjusted
        UNION ALL
        SELECT * FROM other_sales
    ),
    cube_agg AS (
        SELECT
            s_store_id,
            c_email_address,
            SUM(adjusted_price) AS total_adjusted_price,
            COUNT(*) AS cnt
        FROM unioned_sales
        GROUP BY CUBE (s_store_id, c_email_address)
    ),
    store_info AS (
        SELECT s_store_id, s_manager, s_city
        FROM store
        WHERE s_rec_end_date > DATE '1999-12-31'
    )
SELECT
    ca.s_store_id,
    ca.c_email_address,
    ca.total_adjusted_price,
    ca.cnt,
    si.s_manager,
    si.s_city
FROM cube_agg ca
FULL OUTER JOIN store_info si
    ON ca.s_store_id = si.s_store_id
ORDER BY ca.s_store_id NULLS LAST, ca.c_email_address NULLS LAST
