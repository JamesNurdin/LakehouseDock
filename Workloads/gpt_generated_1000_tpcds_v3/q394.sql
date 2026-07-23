SELECT
    d.d_year,
    d.d_quarter_name,
    wp.wp_type,
    i.inv_item_sk,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_fee) AS total_fee,
    MIN(cr.cr_return_amt_inc_tax) AS min_return_inc_tax,
    MAX(cr.cr_return_amt_inc_tax) AS max_return_inc_tax,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    (SELECT MAX(cr3.cr_return_amount)
       FROM catalog_returns cr3
      WHERE cr3.cr_item_sk = i.inv_item_sk) AS max_return_amount_for_item
FROM
    catalog_returns cr
JOIN
    date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
JOIN
    inventory i
      ON i.inv_date_sk = d.d_date_sk
JOIN
    web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_quarter_name = 'Q1'
    AND d.d_current_quarter = 'Y'
    AND i.inv_quantity_on_hand > 500
    AND i.inv_item_sk IN (101410, 101425)
    AND wp.wp_type = 'Content'
    AND wp.wp_char_count > 1000
    AND cr.cr_fee > 30.00
    AND cr.cr_return_quantity >= 2
GROUP BY
    d.d_year,
    d.d_quarter_name,
    wp.wp_type,
    i.inv_item_sk
ORDER BY
    total_return_amount DESC
LIMIT 100
