WITH inv_distinct AS (
    SELECT DISTINCT inv_date_sk, inv_quantity_on_hand
    FROM inventory
)
SELECT
    c.c_customer_id,
    d.d_year,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    CASE
        WHEN SUM(ss.ss_quantity) > 10 THEN 'High Qty'
        ELSE 'Low Qty'
    END AS qty_category,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN inv_distinct i
    ON i.inv_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE d.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND ss.ss_net_paid > 100
  AND i.inv_quantity_on_hand > 0
  AND c.c_birth_month = 5
GROUP BY
    c.c_customer_id,
    d.d_year,
    p.p_promo_name
ORDER BY
    d.d_year,
    total_net_paid DESC
