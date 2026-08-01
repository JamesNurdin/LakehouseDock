WITH
    ws_agg AS (
        SELECT
            ws.ws_web_site_sk,
            ws.ws_sold_date_sk,
            SUM(ws.ws_net_paid) AS total_ws_net_paid,
            SUM(ws.ws_net_profit) AS total_ws_net_profit,
            COUNT(*) AS ws_orders
        FROM web_sales ws
        GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk
    ),
    cs_agg AS (
        SELECT
            cs.cs_call_center_sk,
            cs.cs_sold_date_sk,
            cs.cs_catalog_page_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk,
            SUM(cs.cs_net_paid) AS total_cs_net_paid,
            SUM(cs.cs_net_profit) AS total_cs_net_profit,
            COUNT(*) AS cs_orders
        FROM catalog_sales cs
        GROUP BY
            cs.cs_call_center_sk,
            cs.cs_sold_date_sk,
            cs.cs_catalog_page_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_store_sk,
            sr.sr_returned_date_sk,
            sr.sr_reason_sk,
            SUM(sr.sr_net_loss) AS total_sr_net_loss,
            COUNT(*) AS sr_returns
        FROM store_returns sr
        GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk, sr.sr_reason_sk
    )
SELECT
    d.d_date AS event_date,
    d.d_year,
    web.web_site_id,
    web.web_name,
    web.web_city,
    web.web_state,
    ws.total_ws_net_paid,
    ws.total_ws_net_profit,
    cs.total_cs_net_paid,
    cs.total_cs_net_profit,
    sr.total_sr_net_loss,
    store.s_store_id,
    store.s_city,
    store.s_state,
    call_center.cc_call_center_id,
    call_center.cc_name,
    cp.cp_department,
    cp.cp_catalog_number,
    reason.r_reason_desc,
    (
        SELECT SUM(sr2.sr_net_loss)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = store.s_store_sk
    ) AS store_total_loss,
    RANK() OVER (PARTITION BY d.d_year ORDER BY sr.total_sr_net_loss DESC) AS store_loss_rank,
    SUM(ws.total_ws_net_profit) OVER (
        PARTITION BY web.web_site_sk
        ORDER BY d.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_ws_net_profit,
    CASE WHEN ws.total_ws_net_profit > 100000 THEN 'High' ELSE 'Normal' END AS profit_category
FROM ws_agg ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN cs_agg cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN sr_agg sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN call_center ON cs.cs_call_center_sk = call_center.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store ON sr.sr_store_sk = store.s_store_sk
JOIN reason ON sr.sr_reason_sk = reason.r_reason_sk
LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE
    d.d_year = 2001
    AND web.web_zip IN ('95804', '32477')
    AND call_center.cc_state = 'CA'
    AND store.s_state = 'TX'
    AND cp.cp_department = 'Electronics'
    AND reason.r_reason_desc LIKE '%damaged%'
    AND web.web_manager = 'James Austin'
    AND ca.ca_state = 'CA'
ORDER BY
    d.d_date,
    store_loss_rank,
    ws.total_ws_net_paid DESC
LIMIT 100
