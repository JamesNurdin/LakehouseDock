SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    wp.wp_url,
    wp.wp_type
FROM catalog_returns AS cr
JOIN date_dim AS d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer AS c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page AS wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_customer_sk = c.c_customer_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'TX'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    wp.wp_url,
    wp.wp_type
ORDER BY total_net_loss DESC
LIMIT 100
