WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_store_credit,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_item_sk,
        d.d_year,
        d.d_month_seq,
        c.c_customer_sk,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        inv.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
    WHERE cd.cd_education_status = 'College'
      AND cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_count >= 1
      AND d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND cr.cr_fee > 20
      AND cr.cr_store_credit < 500
      AND inv.inv_quantity_on_hand > 0
),
high_fee_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_fee > 150
),
low_inventory_items AS (
    SELECT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand < 5
),
orders_excluding_low_inventory AS (
    SELECT cr_order_number FROM high_fee_orders
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN inventory inv ON inv.inv_date_sk = cr.cr_returned_date_sk
    WHERE inv.inv_item_sk = cr.cr_item_sk
      AND inv.inv_quantity_on_hand < 5
),
common_customers AS (
    SELECT cr_refunded_customer_sk AS cust_sk FROM catalog_returns
    INTERSECT
    SELECT c.c_customer_sk FROM customer c
    WHERE EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
          AND cd.cd_credit_rating = 'Good'
    )
),
final_agg AS (
    SELECT
        b.c_customer_sk,
        b.d_year,
        SUM(b.cr_return_amount) AS total_return_amount,
        AVG(b.cr_fee) AS avg_fee,
        COUNT(DISTINCT b.cr_order_number) AS cnt_orders,
        MIN(b.cr_return_quantity) AS min_quantity,
        MAX(b.cr_return_quantity) AS max_quantity
    FROM base b
    WHERE b.cr_order_number IN (SELECT cr_order_number FROM orders_excluding_low_inventory)
      AND b.c_customer_sk IN (SELECT cust_sk FROM common_customers)
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = b.cr_item_sk
            AND inv2.inv_quantity_on_hand > 10
      )
    GROUP BY GROUPING SETS (
        (b.c_customer_sk, b.d_year),
        (b.c_customer_sk),
        (b.d_year)
    )
)
SELECT * FROM final_agg
