SELECT
    cr.cr_returned_date_sk AS return_date,
    cs.cs_sold_date_sk AS sale_date,
    cr.cr_item_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cs.cs_quantity,
    cs.cs_net_paid,
    (cr.cr_return_amount - cs.cs_net_paid) AS amount_diff,
    CASE
        WHEN cr.cr_return_amount > cs.cs_net_paid THEN 'OVER_REFUND'
        ELSE 'NORMAL'
    END AS return_flag,
    DENSE_RANK() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY (cr.cr_return_amount - cs.cs_net_paid) DESC) AS return_diff_rank,
    wp.wp_url AS customer_page_url
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN customer c_refund
    ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer c_return
    ON cr.cr_returning_customer_sk = c_return.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_return.c_customer_sk
WHERE cr.cr_returned_date_sk BETWEEN 20000101 AND 20001231
ORDER BY cr.cr_returned_date_sk, return_diff_rank
