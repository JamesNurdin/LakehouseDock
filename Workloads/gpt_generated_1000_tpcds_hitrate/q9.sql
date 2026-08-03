WITH male_sales AS (
    SELECT
        ws_site.web_county,
        'M' AS gender,
        COUNT(ws.ws_order_number) AS order_cnt,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_paid
    FROM web_sales ws
    RIGHT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND ws.ws_sales_price > 20
    GROUP BY ws_site.web_county
),
female_sales AS (
    SELECT
        ws_site.web_county,
        'F' AS gender,
        COUNT(ws.ws_order_number) AS order_cnt,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_paid
    FROM web_sales ws
    RIGHT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND ws.ws_sales_price > 10
    GROUP BY ws_site.web_county
)
SELECT * FROM male_sales
UNION ALL
SELECT * FROM female_sales
LIMIT 100
