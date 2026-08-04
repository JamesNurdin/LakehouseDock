WITH
    returns_agg AS (
        SELECT
            cr.cr_order_number AS order_number,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            MAX(cr.cr_return_ship_cost) AS max_ship_cost,
            MIN(cr.cr_store_credit) AS min_store_credit
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cr.cr_return_amount > 100.00
        GROUP BY cr.cr_order_number
    ),
    sales_agg AS (
        SELECT
            cs.cs_order_number AS order_number,
            SUM(cs.cs_net_paid) AS total_sales,
            COUNT(*) AS sales_cnt,
            MAX(cs.cs_coupon_amt) AS max_coupon,
            MIN(cs.cs_ext_wholesale_cost) AS min_wholesale_cost
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cs.cs_net_paid > 200.00
        GROUP BY cs.cs_order_number
    ),
    intersect_orders AS (
        SELECT order_number FROM returns_agg
        INTERSECT
        SELECT order_number FROM sales_agg
    ),
    except_orders AS (
        SELECT order_number FROM sales_agg
        EXCEPT
        SELECT order_number FROM returns_agg
    ),
    full_joined AS (
        SELECT
            COALESCE(r.order_number, s.order_number) AS order_number,
            r.total_return_amount,
            s.total_sales,
            r.return_cnt,
            s.sales_cnt
        FROM returns_agg r
        FULL OUTER JOIN sales_agg s
            ON r.order_number = s.order_number
    )
SELECT
    fj.order_number,
    fj.total_return_amount,
    fj.total_sales,
    fj.return_cnt,
    fj.sales_cnt
FROM (
    SELECT order_number FROM intersect_orders
    UNION
    SELECT order_number FROM except_orders
) AS combined_orders
JOIN full_joined fj
    ON fj.order_number = combined_orders.order_number
ORDER BY fj.total_sales DESC NULLS LAST, fj.order_number
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
