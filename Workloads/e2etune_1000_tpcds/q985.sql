WITH site_page_metrics AS (
    SELECT
        wsite.web_name AS site_name,
        wp.wp_type AS page_type,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE wsite.web_state = 'CA'
      AND ws.ws_sold_date_sk >= 2451545
    GROUP BY wsite.web_name, wp.wp_type, cd.cd_gender, cd.cd_marital_status
)
SELECT
    site_name,
    page_type,
    gender,
    marital_status,
    net_profit,
    net_paid,
    transaction_count,
    RANK() OVER (PARTITION BY site_name, page_type ORDER BY net_profit DESC) AS profit_rank
FROM site_page_metrics
WHERE net_paid > 1000
ORDER BY site_name, page_type, profit_rank
LIMIT 100
