WITH store_activity AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        'store_sale' AS activity_type,
        ss.ss_net_paid AS amount,
        ss.ss_quantity AS quantity,
        p_latest.p_cost AS promotion_cost,
        CASE WHEN ss.ss_net_paid >= 1000 THEN 'High'
             WHEN ss.ss_net_paid >= 500 THEN 'Medium'
             ELSE 'Low' END AS sales_category,
        SUM(ss.ss_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        ss.ss_sold_date_sk AS activity_date_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN LATERAL (
        SELECT p.p_cost
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
        ORDER BY p.p_start_date_sk DESC
        LIMIT 1
    ) p_latest ON TRUE
    WHERE EXISTS (
        SELECT 1 FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
),
web_activity AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        'web_return' AS activity_type,
        wr.wr_return_amt AS amount,
        wr.wr_return_quantity AS quantity,
        p_latest.p_cost AS promotion_cost,
        CASE WHEN wr.wr_return_amt >= 200 THEN 'High'
             WHEN wr.wr_return_amt >= 100 THEN 'Medium'
             ELSE 'Low' END AS sales_category,
        SUM(wr.wr_return_amt) OVER (PARTITION BY c.c_customer_id ORDER BY wr.wr_returned_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        wr.wr_returned_date_sk AS activity_date_sk
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN LATERAL (
        SELECT p.p_cost
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
        ORDER BY p.p_start_date_sk DESC
        LIMIT 1
    ) p_latest ON TRUE
    WHERE EXISTS (
        SELECT 1 FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
)
SELECT * FROM (
    SELECT * FROM store_activity
    UNION ALL
    SELECT * FROM web_activity
) combined
ORDER BY activity_date_sk, c_customer_id
