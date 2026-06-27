WITH sales_2001 AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01' AND d.d_date <= DATE '2001-12-31'
)
SELECT
    web.web_name,
    cd.cd_gender,
    d.d_year,
    SUM(s.ws_net_profit) AS total_profit,
    AVG(s.ws_ext_discount_amt) AS avg_discount
FROM sales_2001 s
JOIN date_dim d
    ON s.ws_sold_date_sk = d.d_date_sk
JOIN web_site web
    ON s.ws_web_site_sk = web.web_site_sk
JOIN customer_demographics cd
    ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
GROUP BY web.web_name, cd.cd_gender, d.d_year
ORDER BY total_profit DESC
LIMIT 100
