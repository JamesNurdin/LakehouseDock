WITH
    ss_base AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_addr_sk,
            ss.ss_net_paid,
            ss.ss_net_profit
        FROM store_sales ss
    ),
    sr_agg AS (
        SELECT
            sr.sr_ticket_number,
            SUM(sr.sr_net_loss) AS store_return_loss
        FROM store_returns sr
        GROUP BY sr.sr_ticket_number
    ),
    cr_agg AS (
        SELECT
            cr.cr_returned_time_sk AS time_sk,
            cr.cr_refunded_addr_sk AS addr_sk,
            SUM(cr.cr_net_loss) AS catalog_return_loss
        FROM catalog_returns cr
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_department = 'Electronics'
        GROUP BY cr.cr_returned_time_sk, cr.cr_refunded_addr_sk
    ),
    wr_agg AS (
        SELECT
            wr.wr_returned_time_sk AS time_sk,
            wr.wr_refunded_addr_sk AS addr_sk,
            SUM(wr.wr_net_loss) AS web_return_loss
        FROM web_returns wr
        WHERE wr.wr_return_quantity > 1
        GROUP BY wr.wr_returned_time_sk, wr.wr_refunded_addr_sk
    )
SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    td.t_hour,
    ca.ca_state,
    ss.ss_net_paid,
    ss.ss_net_profit,
    COALESCE(sr.store_return_loss, 0) AS store_return_loss,
    COALESCE(cr.catalog_return_loss, 0) AS catalog_return_loss,
    COALESCE(wr.web_return_loss, 0) AS web_return_loss,
    (ss.ss_net_paid
        - COALESCE(sr.store_return_loss, 0)
        - COALESCE(cr.catalog_return_loss, 0)
        - COALESCE(wr.web_return_loss, 0)) AS net_after_losses,
    RANK() OVER (
        ORDER BY (ss.ss_net_paid
            - COALESCE(sr.store_return_loss, 0)
            - COALESCE(cr.catalog_return_loss, 0)
            - COALESCE(wr.web_return_loss, 0)) DESC
    ) AS revenue_rank
FROM ss_base ss
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN sr_agg sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN cr_agg cr
    ON td.t_time_sk = cr.time_sk
   AND ca.ca_address_sk = cr.addr_sk
LEFT JOIN wr_agg wr
    ON td.t_time_sk = wr.time_sk
   AND ca.ca_address_sk = wr.addr_sk
WHERE td.t_hour BETWEEN 8 AND 12
  AND ss.ss_net_paid > 100
  AND ca.ca_state IN ('CA', 'NY', 'TX')
LIMIT 100
