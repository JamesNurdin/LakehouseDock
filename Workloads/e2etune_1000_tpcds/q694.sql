SELECT
    s.s_store_name,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(*) FILTER (WHERE cr.cr_fee > 0) AS returns_with_fee
FROM
    catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND s.s_state IN ('CA', 'TX', 'NY')
    AND cr.cr_return_amount > 0
    AND ca_ret.ca_country = 'United States'
GROUP BY
    s.s_store_name,
    s.s_state,
    d.d_year,
    d.d_month_seq
HAVING
    SUM(cr.cr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
