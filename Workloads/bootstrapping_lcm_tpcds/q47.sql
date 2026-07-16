WITH
    store_return_agg AS (
        SELECT
            sr.sr_store_sk,
            sr.sr_returned_date_sk,
            SUM(sr.sr_return_amt) AS total_store_return_amt,
            SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
            SUM(sr.sr_net_loss) AS total_store_net_loss,
            SUM(sr.sr_return_quantity) AS total_store_return_quantity,
            COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets
        FROM store_returns sr
        GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
    ),
    catalog_return_agg AS (
        SELECT
            cr.cr_returned_date_sk,
            SUM(cr.cr_return_amount) AS total_catalog_return_amt,
            SUM(cr.cr_net_loss) AS total_catalog_net_loss,
            SUM(cr.cr_return_quantity) AS total_catalog_quantity,
            COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_date AS return_date,
    sra.total_store_return_amt,
    sra.total_store_return_amt_inc_tax,
    sra.total_store_net_loss,
    sra.total_store_return_quantity,
    sra.store_return_tickets,
    cra.total_catalog_return_amt,
    cra.total_catalog_net_loss,
    cra.total_catalog_quantity,
    cra.catalog_return_orders,
    ws.web_name,
    ws.web_city,
    CASE
        WHEN d_ws_close.d_date IS NULL OR d_ret.d_date <= d_ws_close.d_date THEN 'Open'
        ELSE 'Closed'
    END AS website_status,
    CASE
        WHEN d_store_closed.d_date IS NULL OR d_ret.d_date < d_store_closed.d_date THEN 'Open'
        ELSE 'Closed'
    END AS store_status,
    (sra.total_store_net_loss + cra.total_catalog_net_loss) AS total_combined_net_loss,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY (sra.total_store_net_loss + cra.total_catalog_net_loss) DESC) AS store_loss_rank,
    ROW_NUMBER() OVER (ORDER BY (sra.total_store_net_loss + cra.total_catalog_net_loss) DESC) AS overall_loss_rank
FROM
    store_return_agg sra
    JOIN catalog_return_agg cra
        ON sra.sr_returned_date_sk = cra.cr_returned_date_sk
    JOIN date_dim d_ret
        ON sra.sr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cr
        ON cra.cr_returned_date_sk = d_cr.d_date_sk
    JOIN store s
        ON sra.sr_store_sk = s.s_store_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
    d_ret.d_year = 2022
ORDER BY
    overall_loss_rank
LIMIT 100
