WITH purchase_activity AS (
    SELECT
        c.c_customer_id,
        SUM(cs.cs_net_paid) AS total_amount,
        COUNT(*) AS txn_count,
        'purchase' AS activity_type
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE i.i_current_price > 100
      AND t.t_meal_time = 'dinner'
    GROUP BY c.c_customer_id
),
return_activity AS (
    SELECT
        c.c_customer_id,
        SUM(cr.cr_net_loss) AS total_amount,
        COUNT(*) AS txn_count,
        'return' AS activity_type
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_net_loss > 200
    GROUP BY c.c_customer_id
)
SELECT DISTINCT
    a.c_customer_id,
    a.total_amount,
    a.txn_count,
    a.activity_type
FROM (
    SELECT * FROM purchase_activity
    UNION ALL
    SELECT * FROM return_activity
) a
ORDER BY a.total_amount DESC
LIMIT 100
