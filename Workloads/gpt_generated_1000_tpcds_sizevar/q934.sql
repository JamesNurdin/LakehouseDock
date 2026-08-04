WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),

full_ws_site AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        wsit.web_name,
        wsit.web_tax_percentage
    FROM sampled_sales ws
    FULL OUTER JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE wsit.web_tax_percentage > 0.05 OR ws.ws_web_site_sk IS NULL
),

full_ws_demo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        cd.cd_credit_rating,
        cd.cd_dep_college_count
    FROM web_sales ws
    FULL OUTER JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'High Risk' OR ws.ws_bill_cdemo_sk IS NULL
),

exclude_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_profit < 0
)

SELECT *
FROM (
    SELECT
        fws.ws_order_number AS order_number,
        fws.ws_net_paid AS net_paid,
        fws.ws_net_profit AS net_profit,
        fws.web_name AS website_name,
        fws.web_tax_percentage AS tax_pct,
        CAST(NULL AS varchar) AS credit_rating,
        CAST(NULL AS integer) AS dep_college_count
    FROM full_ws_site fws

    UNION

    SELECT
        fwd.ws_order_number AS order_number,
        fwd.ws_net_paid AS net_paid,
        CAST(NULL AS decimal(7,2)) AS net_profit,
        CAST(NULL AS varchar) AS website_name,
        CAST(NULL AS decimal(5,2)) AS tax_pct,
        fwd.cd_credit_rating AS credit_rating,
        fwd.cd_dep_college_count AS dep_college_count
    FROM full_ws_demo fwd
) AS combined
EXCEPT
SELECT
    eo.ws_order_number AS order_number,
    CAST(NULL AS decimal(7,2)) AS net_paid,
    CAST(NULL AS decimal(7,2)) AS net_profit,
    CAST(NULL AS varchar) AS website_name,
    CAST(NULL AS decimal(5,2)) AS tax_pct,
    CAST(NULL AS varchar) AS credit_rating,
    CAST(NULL AS integer) AS dep_college_count
FROM exclude_orders eo
LIMIT 100
