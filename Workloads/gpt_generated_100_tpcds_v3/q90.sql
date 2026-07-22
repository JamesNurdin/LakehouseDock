WITH
    base_a AS (
        SELECT
            cc.cc_name,
            cc.cc_city,
            w.w_city AS warehouse_city,
            i1.i_item_id,
            p1.p_promo_name,
            CASE WHEN p2.p_discount_active = 'Y' THEN 'DiscountActive' ELSE 'NoDiscount' END AS discount_status,
            CASE
                WHEN returning_cust.c_preferred_cust_flag = 'Y' THEN 'Returning Preferred'
                WHEN refunded_cust.c_preferred_cust_flag = 'Y' THEN 'Refunded Preferred'
                ELSE 'Regular'
            END AS cust_preferred_status,
            (cr.cr_return_amount - cr.cr_refunded_cash) AS net_return_amount,
            cr.cr_return_quantity,
            returning_cust.c_customer_id AS returning_customer_id,
            refunded_cust.c_customer_id AS refunded_customer_id
        FROM catalog_returns cr
        JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
        JOIN promotion p1 ON i1.i_item_sk = p1.p_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN customer returning_cust ON cr.cr_returning_customer_sk = returning_cust.c_customer_sk
        JOIN customer refunded_cust ON cr.cr_refunded_customer_sk = refunded_cust.c_customer_sk
        JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
        JOIN promotion p2 ON i2.i_item_sk = p2.p_item_sk
        JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
        WHERE cr.cr_return_amount > 50
          AND cc.cc_state = 'CA'
          AND w.w_state = 'CA'
          AND i1.i_category = 'Electronics'
    ),
    base_b AS (
        SELECT
            cc.cc_name,
            cc.cc_city,
            w.w_city AS warehouse_city,
            i1.i_item_id,
            p1.p_promo_name,
            CASE WHEN p2.p_discount_active = 'Y' THEN 'DiscountActive' ELSE 'NoDiscount' END AS discount_status,
            CASE
                WHEN returning_cust.c_preferred_cust_flag = 'Y' THEN 'Returning Preferred'
                WHEN refunded_cust.c_preferred_cust_flag = 'Y' THEN 'Refunded Preferred'
                ELSE 'Regular'
            END AS cust_preferred_status,
            (cr.cr_return_amount - cr.cr_refunded_cash) AS net_return_amount,
            cr.cr_return_quantity,
            returning_cust.c_customer_id AS returning_customer_id,
            refunded_cust.c_customer_id AS refunded_customer_id
        FROM catalog_returns cr
        JOIN item i1 ON cr.cr_item_sk = i1.i_item_sk
        JOIN promotion p1 ON i1.i_item_sk = p1.p_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN customer returning_cust ON cr.cr_returning_customer_sk = returning_cust.c_customer_sk
        JOIN customer refunded_cust ON cr.cr_refunded_customer_sk = refunded_cust.c_customer_sk
        JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
        JOIN promotion p2 ON i2.i_item_sk = p2.p_item_sk
        JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
        WHERE cr.cr_return_amount <= 50
          AND cc.cc_state = 'TX'
          AND w.w_state = 'TX'
          AND i1.i_category = 'Furniture'
    )
SELECT
    final.cc_name,
    final.cc_city,
    final.warehouse_city,
    final.i_item_id,
    final.p_promo_name,
    final.discount_status,
    final.cust_preferred_status,
    SUM(final.net_return_amount) AS total_net_return_amount,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT final.returning_customer_id) AS distinct_returning_customers,
    COUNT(DISTINCT final.refunded_customer_id) AS distinct_refunded_customers,
    AVG(final.cr_return_quantity) AS avg_return_quantity
FROM (
    SELECT
        cc_name,
        cc_city,
        warehouse_city,
        i_item_id,
        p_promo_name,
        discount_status,
        cust_preferred_status,
        net_return_amount,
        cr_return_quantity,
        returning_customer_id,
        refunded_customer_id
    FROM base_a
    UNION ALL
    SELECT
        cc_name,
        cc_city,
        warehouse_city,
        i_item_id,
        p_promo_name,
        discount_status,
        cust_preferred_status,
        net_return_amount,
        cr_return_quantity,
        returning_customer_id,
        refunded_customer_id
    FROM base_b
) AS final
GROUP BY
    final.cc_name,
    final.cc_city,
    final.warehouse_city,
    final.i_item_id,
    final.p_promo_name,
    final.discount_status,
    final.cust_preferred_status
ORDER BY total_net_return_amount DESC
LIMIT 100
