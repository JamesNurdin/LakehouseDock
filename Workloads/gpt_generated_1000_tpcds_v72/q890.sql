WITH
sr AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d_s.d_year,
        ca_s.ca_state
    FROM store_returns sr
    JOIN date_dim d_s
        ON sr.sr_returned_date_sk = d_s.d_date_sk
    JOIN customer_address ca_s
        ON sr.sr_addr_sk = ca_s.ca_address_sk
),
cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        d_c.d_year AS cr_year,
        ca_r.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state
    FROM catalog_returns cr
    JOIN date_dim d_c
        ON cr.cr_returned_date_sk = d_c.d_date_sk
    JOIN customer_address ca_r
        ON cr.cr_refunded_addr_sk = ca_r.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
),
ws AS (
    SELECT
        ws.web_site_id,
        ws.web_state,
        d_o.d_year AS open_year,
        d_cl.d_year AS close_year
    FROM web_site ws
    JOIN date_dim d_o
        ON ws.web_open_date_sk = d_o.d_date_sk
    JOIN date_dim d_cl
        ON ws.web_close_date_sk = d_cl.d_date_sk
),
wp AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_type,
        d_cr.d_year AS creation_year,
        d_ac.d_year AS access_year,
        wp.wp_char_count,
        wp.wp_link_count
    FROM web_page wp
    JOIN date_dim d_cr
        ON wp.wp_creation_date_sk = d_cr.d_date_sk
    JOIN date_dim d_ac
        ON wp.wp_access_date_sk = d_ac.d_date_sk
)
SELECT
    sr.ca_state AS store_state,
    ws.web_state AS website_state,
    sr.d_year AS transaction_year,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    AVG(wp.wp_char_count) AS avg_page_char_count,
    SUM(wp.wp_link_count) AS total_page_links
FROM sr
JOIN cr
    ON sr.d_year = cr.cr_year
JOIN ws
    ON sr.d_year = ws.open_year
JOIN wp
    ON sr.d_year = wp.creation_year
GROUP BY
    sr.ca_state,
    ws.web_state,
    sr.d_year
LIMIT 100
