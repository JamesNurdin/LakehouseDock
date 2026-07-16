SELECT
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ship.d_year AS shipto_year,
    d_sales.d_year AS sales_year,
    COUNT(DISTINCT cr.cr_order_number) AS total_return_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT refunded.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT returning.c_customer_sk) AS distinct_returning_customers,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN cr.cr_return_tax > 0 THEN cr.cr_return_tax ELSE 0 END) AS total_return_tax,
    COUNT(*) FILTER (WHERE cr.cr_return_tax > 0) AS returns_with_tax,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer refunded
    ON cr.cr_refunded_customer_sk = refunded.c_customer_sk
JOIN customer returning
    ON cr.cr_returning_customer_sk = returning.c_customer_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_ship
    ON refunded.c_first_shipto_date_sk = d_ship.d_date_sk
LEFT JOIN date_dim d_sales
    ON refunded.c_first_sales_date_sk = d_sales.d_date_sk
WHERE d_ret.d_year BETWEEN 1999 AND 2002
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ship.d_year,
    d_sales.d_year
ORDER BY total_net_loss DESC
LIMIT 100
