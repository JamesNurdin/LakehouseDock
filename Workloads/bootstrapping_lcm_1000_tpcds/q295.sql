SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    CASE
        WHEN date_diff('day', d.d_date, ds.d_date) = 0 THEN 'SameDay'
        WHEN date_diff('day', d.d_date, ds.d_date) BETWEEN 1 AND 3 THEN '1-3 Days'
        ELSE '4+ Days'
    END AS ship_delay_bucket,
    SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN date_dim ds
    ON ws.ws_ship_date_sk = ds.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_state,
    CASE
        WHEN date_diff('day', d.d_date, ds.d_date) = 0 THEN 'SameDay'
        WHEN date_diff('day', d.d_date, ds.d_date) BETWEEN 1 AND 3 THEN '1-3 Days'
        ELSE '4+ Days'
    END
HAVING SUM(ws.ws_net_paid_inc_ship_tax) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
