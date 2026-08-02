WITH cat_ret AS (
    SELECT
        cc.cc_city AS city,
        sm.sm_type AS ship_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        concat('CC ', cc.cc_city) AS city_label,
        substring(cc.cc_city FROM 1 FOR 3) AS city_prefix,
        substring(cc.cc_city FROM 1 FOR 3) AS city_prefix_expr
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_city, 'ville$')
      AND sm.sm_code LIKE 'A%'
    GROUP BY cc.cc_city, sm.sm_type, substring(cc.cc_city FROM 1 FOR 3)
),
web_ret AS (
    SELECT
        wsite.web_city AS city,
        sm.sm_type AS ship_type,
        SUM(wr.wr_net_loss) AS total_net_loss,
        concat('WEB ', wsite.web_city) AS city_label,
        substring(wsite.web_name FROM 1 FOR 5) AS city_prefix,
        substring(wsite.web_name FROM 1 FOR 5) AS city_prefix_expr
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(wsite.web_city, '^San')
      AND wsite.web_name LIKE '%Store%'
    GROUP BY wsite.web_city, sm.sm_type, substring(wsite.web_name FROM 1 FOR 5)
)
SELECT
    city,
    ship_type,
    total_net_loss,
    city_label,
    city_prefix
FROM (
    SELECT city, ship_type, total_net_loss, city_label, city_prefix FROM cat_ret
    UNION ALL
    SELECT city, ship_type, total_net_loss, city_label, city_prefix FROM web_ret
) combined
WHERE city NOT IN (
    SELECT cc_city
    FROM call_center
    WHERE cc_state = 'TX'
)
ORDER BY total_net_loss DESC
LIMIT 100
