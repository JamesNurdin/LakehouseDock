SELECT
    cr.cr_order_number,
    cr.cr_returned_date_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    c_refunded.c_customer_id AS refunded_customer_id,
    c_refunded.c_first_name AS refunded_first_name,
    c_refunded.c_last_name AS refunded_last_name,
    c_returning.c_customer_id AS returning_customer_id,
    c_returning.c_first_name AS returning_first_name,
    c_returning.c_last_name AS returning_last_name,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    ws_open.web_name AS web_site_name,
    ws_open.web_state AS web_site_state,
    ws_open.web_tax_percentage AS web_site_tax,
    CASE
        WHEN ws_open.web_open_date_sk <= cr.cr_returned_date_sk
         AND (ws_open.web_close_date_sk IS NULL OR ws_open.web_close_date_sk >= cr.cr_returned_date_sk)
        THEN 'Active'
        ELSE 'Inactive'
    END AS web_site_status,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    (cr.cr_net_loss * (1 + COALESCE(s.s_tax_percentage, 0))) AS net_loss_with_store_tax,
    ROW_NUMBER() OVER (PARTITION BY c_refunded.c_customer_sk ORDER BY cr.cr_returned_date_sk DESC) AS return_rank_per_customer,
    SUM(cr.cr_net_loss) OVER (PARTITION BY s.s_store_name) AS total_store_net_loss,
    AVG(cr.cr_return_quantity) OVER (PARTITION BY ws_open.web_name) AS avg_return_qty_per_site
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws_open ON ws_open.web_open_date_sk = d.d_date_sk
WHERE cr.cr_net_loss > 0
  AND d.d_year BETWEEN 2000 AND 2005
ORDER BY cr.cr_net_loss DESC, d.d_date ASC
LIMIT 200
