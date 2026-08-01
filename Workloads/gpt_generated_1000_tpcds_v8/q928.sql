WITH
    sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (5)    -- sample roughly 5% of rows
    ),
    sales_enriched AS (
        SELECT
            ss.cs_order_number,
            ss.cs_item_sk,
            ss.cs_ship_mode_sk,
            ss.cs_ext_sales_price,
            i.i_item_desc,
            i.i_item_id,
            sm.sm_type,
            c.c_customer_id,
            c.c_email_address,
            CASE WHEN regexp_like(i.i_item_desc, '[0-9]{2}') THEN 'HasDigits' ELSE 'NoDigits' END AS desc_flag,
            CASE WHEN c.c_email_address LIKE '%@example.com' THEN 1 ELSE 0 END AS is_example_email,
            CONCAT(SUBSTRING(c.c_first_name, 1, 1), SUBSTRING(c.c_last_name, 1, 1)) AS initials,
            regexp_extract(i.i_item_desc, '([A-Z]{3})', 1) AS extracted_code
        FROM sampled_sales ss
        JOIN item i ON ss.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer c ON ss.cs_bill_customer_sk = c.c_customer_sk
        WHERE regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
    ),
    returns_set AS (
        SELECT cr_order_number
        FROM catalog_returns
    ),
    sales_no_return AS (
        SELECT *
        FROM sales_enriched se
        WHERE NOT EXISTS (
            SELECT 1 FROM returns_set r WHERE r.cr_order_number = se.cs_order_number
        )
    ),
    order_numbers_sales AS (
        SELECT cs_order_number FROM catalog_sales
    ),
    order_numbers_returns AS (
        SELECT cr_order_number FROM catalog_returns
    ),
    intersect_orders AS (
        SELECT cs_order_number FROM order_numbers_sales
        INTERSECT
        SELECT cr_order_number FROM order_numbers_returns
    ),
    except_orders AS (
        SELECT cs_order_number FROM order_numbers_sales
        EXCEPT
        SELECT cr_order_number FROM order_numbers_returns
    ),
    full_outer AS (
        SELECT
            s.cs_order_number,
            s.cs_ext_sales_price,
            r.cr_return_amount
        FROM catalog_sales s
        FULL OUTER JOIN catalog_returns r
            ON s.cs_order_number = r.cr_order_number
    ),
    agg_sales AS (
        SELECT
            'SalesOnly' AS source,
            se.desc_flag,
            se.sm_type,
            COUNT(DISTINCT se.cs_order_number) AS order_cnt,
            SUM(se.cs_ext_sales_price) AS revenue,
            SUM(CASE WHEN se.is_example_email = 1 THEN se.cs_ext_sales_price ELSE 0 END) AS example_email_rev
        FROM sales_no_return se
        GROUP BY se.desc_flag, se.sm_type
    ),
    agg_full AS (
        SELECT
            'FullOuter' AS source,
            CASE WHEN f.cs_ext_sales_price IS NULL THEN 'OnlyReturn' ELSE 'Both' END AS side_flag,
            COUNT(DISTINCT f.cs_order_number) AS order_cnt,
            SUM(COALESCE(f.cs_ext_sales_price, 0)) AS sales_total,
            SUM(COALESCE(f.cr_return_amount, 0)) AS return_total
        FROM full_outer f
        GROUP BY CASE WHEN f.cs_ext_sales_price IS NULL THEN 'OnlyReturn' ELSE 'Both' END
    ),
    intersect_list AS (
        SELECT 'Intersect' AS source, cs_order_number AS order_number FROM intersect_orders
    ),
    except_list AS (
        SELECT 'Except' AS source, cs_order_number AS order_number FROM except_orders
    ),
    combined_set AS (
        SELECT source, order_number FROM intersect_list
        UNION ALL
        SELECT source, order_number FROM except_list
    )
SELECT *
FROM (
    SELECT
        source,
        desc_flag AS category,
        sm_type,
        order_cnt,
        revenue,
        example_email_rev,
        NULL AS order_number
    FROM agg_sales

    UNION ALL

    SELECT
        source,
        side_flag AS category,
        NULL AS sm_type,
        order_cnt,
        sales_total AS revenue,
        NULL AS example_email_rev,
        NULL AS order_number
    FROM agg_full

    UNION ALL

    SELECT
        source,
        NULL AS category,
        NULL AS sm_type,
        NULL AS order_cnt,
        NULL AS revenue,
        NULL AS example_email_rev,
        order_number
    FROM combined_set
) final_result
ORDER BY revenue DESC NULLS LAST
LIMIT 100
