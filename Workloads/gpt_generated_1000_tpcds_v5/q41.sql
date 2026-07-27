WITH joined_data AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        s.s_state,
        s.s_store_name,
        wsite.web_name,
        wsite.web_country,
        cr.cr_return_amount,
        cr.cr_return_tax,
        sr.sr_return_amt,
        sr.sr_return_tax,
        ws.ws_ext_list_price,
        ws.ws_net_paid,
        ws.ws_order_number
    FROM catalog_returns cr
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE cr.cr_ship_mode_sk IN (12, 14)
      AND cr.cr_reason_sk = 56
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND wsite.web_country = 'United States'
      AND ws.ws_ext_list_price > 3000
)
SELECT
    cd_gender,
    cd_marital_status,
    s_state,
    web_name,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(ws_ext_list_price) AS total_sales_price,
    AVG(ws_net_paid) AS avg_net_paid,
    MIN(ws_net_paid) AS min_net_paid,
    MAX(ws_net_paid) AS max_net_paid
FROM joined_data
GROUP BY cd_gender, cd_marital_status, s_state, web_name
ORDER BY total_sales_price DESC
LIMIT 100
