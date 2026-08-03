WITH
    cat AS (
        SELECT
            cs.cs_order_number,
            c.c_customer_id,
            cs.cs_ext_sales_price AS sales_amount,
            sm.sm_type
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        WHERE cs.cs_ext_tax > 10.0
    ),
    web AS (
        SELECT
            ws.ws_order_number,
            c.c_customer_id,
            ws.ws_ext_sales_price AS sales_amount,
            sm.sm_type
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE ws.ws_ext_tax > 10.0
    ),
    full_join AS (
        SELECT
            COALESCE(cat.c_customer_id, web.c_customer_id) AS customer_id,
            cat.sales_amount AS cat_sales,
            web.sales_amount AS web_sales,
            COALESCE(cat.sm_type, web.sm_type) AS ship_mode_type
        FROM cat
        FULL OUTER JOIN web
            ON cat.c_customer_id = web.c_customer_id
    ),
    full_adjusted AS (
        SELECT
            customer_id,
            CASE
                WHEN ship_mode_type = 'AIR' THEN COALESCE(cat_sales, 0) * 0.9
                ELSE COALESCE(cat_sales, 0)
            END AS adjusted_sales,
            'FullJoin' AS source
        FROM full_join
        WHERE customer_id IS NOT NULL
    ),
    intersect_customers AS (
        SELECT c_customer_id FROM cat
        INTERSECT
        SELECT c_customer_id FROM web
    ),
    intersect_set AS (
        SELECT c_customer_id AS customer_id, NULL AS adjusted_sales, 'Intersect' AS source
        FROM intersect_customers
    ),
    except_customers AS (
        SELECT c_customer_id FROM cat
        EXCEPT
        SELECT c_customer_id FROM web
    ),
    except_set AS (
        SELECT c_customer_id AS customer_id, NULL AS adjusted_sales, 'Except' AS source
        FROM except_customers
    )
SELECT
    customer_id,
    adjusted_sales,
    source
FROM (
    SELECT * FROM full_adjusted
    UNION
    SELECT * FROM intersect_set
    UNION
    SELECT * FROM except_set
) combined
ORDER BY customer_id ASC, source ASC
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
