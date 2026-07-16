SELECT
    d_cr.d_year,
    d_cr.d_month_seq,
    i.i_category,
    s.s_state,
    wp.wp_type,
    CASE 
        WHEN s.s_state IN ('CA','OR','WA','NV','AZ') THEN 'West'
        WHEN s.s_state IN ('NY','NJ','CT','MA','PA') THEN 'East'
        ELSE 'Other'
    END AS region,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(CASE WHEN cr.cr_return_quantity > 1 THEN cr.cr_return_amount ELSE 0 END) AS multi_item_return_amount,
    SUM(CASE WHEN cr.cr_return_quantity = 1 THEN cr.cr_return_amount ELSE 0 END) AS single_item_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customers
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_cr.d_date_sk AND wp.wp_access_date_sk = d_cr.d_date_sk
WHERE d_cr.d_year = 2022
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY
    d_cr.d_year,
    d_cr.d_month_seq,
    i.i_category,
    s.s_state,
    wp.wp_type,
    CASE 
        WHEN s.s_state IN ('CA','OR','WA','NV','AZ') THEN 'West'
        WHEN s.s_state IN ('NY','NJ','CT','MA','PA') THEN 'East'
        ELSE 'Other'
    END
HAVING COUNT(cr.cr_order_number) > 50
ORDER BY total_return_amount DESC
LIMIT 100
