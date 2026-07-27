SELECT
    sub.web_site_id,
    sub.web_name,
    sub.total_net_profit,
    sub.source
FROM (
    SELECT
        site.web_site_id,
        site.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        'BirthBefore1960' AS source
    FROM web_sales ws
    JOIN customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE cu.c_birth_year < 1960
      AND site.web_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
    GROUP BY site.web_site_id, site.web_name

    UNION ALL

    SELECT
        site.web_site_id,
        site.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        'HomePagePreferred' AS source
    FROM web_sales ws
    JOIN customer cu ON ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'home'
      AND cu.c_preferred_cust_flag = 'Y'
      AND ws.ws_ext_tax > 20
    GROUP BY site.web_site_id, site.web_name
) AS sub
ORDER BY sub.total_net_profit DESC
LIMIT 100
