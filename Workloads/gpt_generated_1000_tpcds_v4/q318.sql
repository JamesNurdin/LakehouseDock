WITH agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        p.p_promo_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_net_paid) AS total_sales_paid,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cr.cr_return_tax > 10
        AND cr.cr_return_amount < 5000
        AND cs.cs_quantity >= 2
        AND cs.cs_sales_price BETWEEN 20 AND 500
        AND p.p_channel_demo = 'N'
        AND w.w_state = 'CA'
        AND inv.inv_quantity_on_hand > 0
        AND sr.sr_return_tax > 20
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, p.p_promo_id
)
SELECT
    a.w_warehouse_name,
    a.p_promo_id,
    a.total_return_amount,
    a.total_sales_paid,
    a.unique_customers,
    a.total_sales_price,
    a.total_net_loss,
    AVG(a.total_return_amount) OVER (PARTITION BY a.w_warehouse_sk) AS avg_return_per_warehouse,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_sk ORDER BY a.total_return_amount DESC) AS rn
FROM agg a
WHERE a.total_return_amount > (
    SELECT AVG(total_return_amount) FROM agg
)
ORDER BY a.total_return_amount DESC
LIMIT 100
