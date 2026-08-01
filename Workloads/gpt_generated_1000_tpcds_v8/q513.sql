WITH
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (5)
    ),
    sales_agg AS (
        SELECT
            i.i_item_id AS item_id,
            w.w_warehouse_id AS warehouse_id,
            SUM(cs.cs_quantity) AS total_qty,
            SUM(cs.cs_net_paid) AS total_net_paid,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
            COUNT(DISTINCT cs.cs_bill_cdemo_sk) AS distinct_bill_cust_demo,
            COUNT(DISTINCT cd.cd_gender) AS distinct_genders,
            COUNT(DISTINCT cd_ship.cd_gender) AS distinct_ship_genders
        FROM cs_sample cs
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_demographics cd_ship
            ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE i.i_brand_id = 1
        GROUP BY i.i_item_id, w.w_warehouse_id
    ),
    returns_agg AS (
        SELECT
            i2.i_item_id AS item_id,
            w2.w_warehouse_id AS warehouse_id,
            SUM(cr.cr_return_quantity) AS total_return_qty,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
            COUNT(DISTINCT cr.cr_refunded_cdemo_sk) AS distinct_refunded_demo
        FROM catalog_returns cr
        JOIN item i2
            ON cr.cr_item_sk = i2.i_item_sk
        LEFT JOIN warehouse w2
            ON cr.cr_warehouse_sk = w2.w_warehouse_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN call_center cc2
            ON cr.cr_call_center_sk = cc2.cc_call_center_sk
        GROUP BY i2.i_item_id, w2.w_warehouse_id
    ),
    intersect_cnt AS (
        SELECT COUNT(*) AS cnt
        FROM (
            SELECT cs_order_number FROM catalog_sales
            INTERSECT
            SELECT cr_order_number FROM catalog_returns
        ) t
    ),
    except_cnt AS (
        SELECT COUNT(*) AS cnt
        FROM (
            SELECT cs_order_number FROM catalog_sales
            EXCEPT
            SELECT cr_order_number FROM catalog_returns
        ) t
    )
SELECT
    s.item_id,
    s.warehouse_id,
    s.total_qty,
    s.total_net_paid,
    s.distinct_orders,
    s.distinct_bill_cust_demo,
    s.distinct_genders,
    s.distinct_ship_genders,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders,
    COALESCE(r.distinct_refunded_demo, 0) AS distinct_refunded_demo,
    ic.cnt AS intersect_order_count,
    ec.cnt AS sales_not_returned_order_count
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.item_id = r.item_id
    AND s.warehouse_id = r.warehouse_id
CROSS JOIN intersect_cnt ic
CROSS JOIN except_cnt ec
WHERE s.total_net_paid > 1000
ORDER BY s.total_net_paid DESC
OFFSET 0
LIMIT 100
