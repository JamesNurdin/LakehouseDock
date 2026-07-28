WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        ws.ws_net_profit,
        sm.sm_carrier,
        sm.sm_ship_mode_id,
        dr.d_year,
        regexp_extract(c.c_email_address, '@([^.]*)\\..*', 1) AS email_domain
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse wh
        ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = dr.d_date_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = wh.w_warehouse_sk
)
SELECT
    sm_carrier,
    email_domain,
    d_year,
    sum(cr_return_amount) AS total_return_amount,
    sum(ws_net_profit) AS total_net_profit,
    count(*) AS transaction_count,
    sm_carrier || '_' || email_domain AS carrier_email_label
FROM joined_data
WHERE regexp_like(sm_ship_mode_id, '^AAAAAAA.*A$')
  AND regexp_like(email_domain, '^g.*')
GROUP BY sm_carrier, email_domain, d_year
