WITH billed AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_sales_price,
        cd.cd_credit_rating,
        ws.ws_web_site_sk,
        web.web_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND ws.ws_ext_tax > 10
      AND web.web_country = 'United States'
),
shipped AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_sales_price,
        cd.cd_credit_rating,
        ws.ws_web_site_sk,
        web.web_name,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_ext_tax DESC) AS rnk
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND ws.ws_sales_price > 30
      AND web.web_country = 'United States'
)
SELECT
    combined.order_number,
    combined.ws_net_profit AS net_profit,
    combined.ws_ext_tax AS ext_tax,
    combined.ws_sales_price AS sales_price,
    combined.cd_credit_rating AS credit_rating,
    combined.web_name,
    combined.ws_web_site_sk AS site_key,
    combined.rank_type,
    combined.rank_value
FROM (
    SELECT
        order_number,
        ws_net_profit,
        ws_ext_tax,
        ws_sales_price,
        cd_credit_rating,
        ws_web_site_sk,
        web_name,
        'billed' AS rank_type,
        rn AS rank_value
    FROM billed
    WHERE rn <= 3

    UNION ALL

    SELECT
        order_number,
        ws_net_profit,
        ws_ext_tax,
        ws_sales_price,
        cd_credit_rating,
        ws_web_site_sk,
        web_name,
        'shipped' AS rank_type,
        rnk AS rank_value
    FROM shipped
    WHERE rnk <= 3
) AS combined
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_sales ws2
    WHERE ws2.ws_order_number = combined.order_number
      AND ws2.ws_net_profit > 1000
)
ORDER BY site_key, rank_type, rank_value
