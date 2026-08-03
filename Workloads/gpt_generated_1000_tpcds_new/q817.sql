WITH catalog_activity AS (
    SELECT
        COALESCE(cs_cust.c_customer_id, cr_cust.c_customer_id) AS customer_id,
        cs.cs_net_paid AS sale_amount,
        cr.cr_refunded_cash AS return_amount,
        COALESCE(cs_date.d_date, cr_date.d_date) AS activity_date,
        'catalog' AS source
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN date_dim cs_date
        ON cs.cs_sold_date_sk = cs_date.d_date_sk
    LEFT JOIN date_dim cr_date
        ON cr.cr_returned_date_sk = cr_date.d_date_sk
    LEFT JOIN customer cs_cust
        ON cs.cs_bill_customer_sk = cs_cust.c_customer_sk
    LEFT JOIN customer cr_cust
        ON cr.cr_refunded_customer_sk = cr_cust.c_customer_sk
    WHERE (
            (cs.cs_item_sk IS NOT NULL AND cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics'))
            OR
            (cr.cr_item_sk IS NOT NULL AND cr.cr_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics'))
          )
      AND (
            (cs_date.d_year = 2000)
            OR
            (cr_date.d_year = 2000)
          )
),
inventory_activity AS (
    SELECT
        CAST(NULL AS varchar) AS customer_id,
        CAST(NULL AS decimal(7,2)) AS sale_amount,
        CAST(NULL AS decimal(7,2)) AS return_amount,
        d.d_date AS activity_date,
        'inventory' AS source
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND d.d_year = 2000
),
combined AS (
    SELECT * FROM catalog_activity
    UNION
    SELECT * FROM inventory_activity
)
SELECT
    customer_id,
    sale_amount,
    return_amount,
    activity_date,
    source,
    row_number() OVER (ORDER BY activity_date DESC) AS rn
FROM combined
ORDER BY rn
LIMIT 100
