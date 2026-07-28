WITH filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_list_price,
        sm.sm_carrier,
        sm.sm_contract,
        wsite.web_country
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_credit_rating = 'Excellent'
      AND sm.sm_carrier IN ('DHL', 'DIAMOND')
      AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
      AND wsite.web_country = 'United States'
      AND ws.ws_quantity >= 30
      AND ws.ws_ext_list_price > 1000
)
SELECT
    cd_gender,
    cd_marital_status,
    sm_carrier,
    web_country,
    COUNT(DISTINCT ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws_order_number) AS web_transactions,
    SUM(ss_net_paid) AS store_net_paid,
    SUM(ws_net_paid) AS web_net_paid,
    AVG(ws_quantity) AS avg_web_quantity,
    MIN(ws_net_profit) AS min_web_profit,
    MAX(ss_net_profit) AS max_store_profit
FROM filtered
GROUP BY cd_gender, cd_marital_status, sm_carrier, web_country
ORDER BY store_net_paid DESC
LIMIT 100
