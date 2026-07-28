WITH joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_date_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss AS wr_net_loss,
        wp.wp_type,
        ws.web_name,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        inv.inv_quantity_on_hand
    FROM catalog_returns cr
    INNER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
)
SELECT
    d_year,
    d_month_seq,
    web_name,
    wp_type,
    COUNT(DISTINCT cr_order_number) AS orders_returned,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    SUM(wr_return_amt) AS total_web_return_amt,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
FROM joined_data
WHERE d_year = 2001
  AND d_week_seq BETWEEN 10 AND 20
  AND cr_return_amount > 100.00
  AND wp_type IN ('product', 'category')
GROUP BY d_year, d_month_seq, web_name, wp_type
HAVING COUNT(DISTINCT cr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 100
