SELECT
    web_name,
    cd_gender,
    role,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit,
    SUM(order_count) AS order_count,
    GROUPING(web_name) AS g_web_name,
    GROUPING(cd_gender) AS g_cd_gender,
    GROUPING(role) AS g_role
FROM (
    SELECT
        w.web_name,
        c.cd_gender,
        'Bill' AS role,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer_demographics c ON ws.ws_bill_cdemo_sk = c.cd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND c.cd_marital_status = 'M'
      AND ws.ws_ext_tax > 10
    GROUP BY w.web_name, c.cd_gender

    UNION ALL

    SELECT
        w.web_name,
        c.cd_gender,
        'Ship' AS role,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer_demographics c ON ws.ws_ship_cdemo_sk = c.cd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND c.cd_marital_status = 'S'
      AND ws.ws_ext_tax > 10
    GROUP BY w.web_name, c.cd_gender
) t
GROUP BY GROUPING SETS (
    (web_name, cd_gender, role),
    (web_name, role),
    (role),
    (web_name, cd_gender),
    (web_name),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
