WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN call_center rc_cc
        ON cr.cr_call_center_sk = rc_cc.cc_call_center_sk
    JOIN customer cust_refund
        ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
    JOIN customer_demographics cd_refund
        ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer cust_returning
        ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
),
combined AS (
    SELECT
        s.cs_order_number,
        s.cs_net_paid,
        r.cr_return_amount,
        r.cr_return_quantity,
        r.r_reason_desc,
        ARRAY[ s.cs_quantity, r.cr_return_quantity ] AS qty_array,
        s.cs_call_center_sk
    FROM sales s
    JOIN returns r
        ON s.cs_order_number = r.cr_order_number
       AND s.cs_item_sk = r.cr_item_sk
),
gift_orders AS (
    SELECT cr_order_number
    FROM returns
    WHERE r_reason_desc LIKE '%Gift exchange%'
),
other_reason_orders AS (
    SELECT cr_order_number
    FROM returns
    WHERE r_reason_desc NOT LIKE '%Gift exchange%'
),
union_orders AS (
    SELECT cr_order_number FROM gift_orders
    UNION
    SELECT cr_order_number FROM other_reason_orders
),
exclude_gift AS (
    SELECT cr_order_number
    FROM returns
    EXCEPT
    SELECT cr_order_number FROM gift_orders
),
intersect_orders AS (
    SELECT cr_order_number
    FROM returns
    WHERE cr_return_amount > 0
    INTERSECT
    SELECT cs_order_number
    FROM sales
    WHERE cs_net_paid > 1000
),
final AS (
    SELECT
        cc.cc_call_center_id,
        SUM(c.cs_net_paid) AS total_sales,
        SUM(c.cr_return_amount) AS total_returns,
        SUM(qty) AS total_quantity
    FROM combined c
    CROSS JOIN UNNEST(c.qty_array) AS t(qty)
    JOIN call_center cc
        ON c.cs_call_center_sk = cc.cc_call_center_sk
    WHERE c.cs_order_number IN (SELECT cr_order_number FROM exclude_gift)
      AND c.cs_order_number IN (SELECT cr_order_number FROM intersect_orders)
    GROUP BY cc.cc_call_center_id
)
SELECT *
FROM final
LIMIT 100
