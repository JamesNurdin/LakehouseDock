WITH joined_data AS (
    SELECT
        d_sale.d_year                       AS d_year,
        sm.sm_type                          AS sm_type,
        r.r_reason_desc                     AS r_reason_desc,
        ss.ss_net_paid                      AS ss_net_paid,
        ws.ws_net_paid                      AS ws_net_paid,
        sr.sr_net_loss                      AS sr_net_loss
    FROM store_sales ss
    JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sale.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_site_open
        ON we.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON we.web_close_date_sk = d_site_close.d_date_sk
    JOIN date_dim d_page_creation
        ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
)
SELECT
    d_year,
    sm_type,
    r_reason_desc,
    SUM(ss_net_paid)               AS total_store_sales,
    SUM(ws_net_paid)               AS total_web_sales,
    SUM(sr_net_loss)               AS total_return_loss,
    CASE
        WHEN SUM(ss_net_paid) > SUM(ws_net_paid) THEN 'Store higher'
        ELSE 'Web higher'
    END                           AS revenue_comparison
FROM joined_data
GROUP BY ROLLUP (d_year, sm_type, r_reason_desc)
HAVING (SUM(ss_net_paid) + SUM(ws_net_paid) + SUM(sr_net_loss)) > 0
ORDER BY d_year, sm_type, r_reason_desc
LIMIT 100
