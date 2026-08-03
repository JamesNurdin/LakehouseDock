WITH first_part AS (
    SELECT
        ws.ws_order_number AS order_number,
        i.i_item_id AS identifier,
        CASE WHEN ws.ws_coupon_amt > 1000 THEN 'High Coupon' ELSE 'Low Coupon' END AS category,
        ws.ws_net_paid_inc_ship_tax AS total_paid,
        (
            SELECT sum(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
        ) AS agg_metric,
        word AS desc_word
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    WHERE ws.ws_net_paid_inc_ship_tax > 3000
      AND wsite.web_zip = '33604'
),
second_part AS (
    SELECT
        ws.ws_order_number AS order_number,
        hd.hd_buy_potential AS identifier,
        CASE WHEN hd.hd_dep_count > 2 THEN 'Many Dependents' ELSE 'Few Dependents' END AS category,
        ws.ws_net_paid AS total_paid,
        (
            SELECT sum(ws2.ws_net_paid)
            FROM web_sales ws2
            WHERE ws2.ws_bill_hdemo_sk = hd.hd_demo_sk
        ) AS agg_metric,
        word AS desc_word
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    CROSS JOIN UNNEST(split(wsite.web_name, ' ')) AS t(word)
    WHERE hd.hd_income_band_sk IS NOT NULL
      AND wsite.web_class = 'Unknown'
)
SELECT
    order_number,
    identifier,
    category,
    total_paid,
    agg_metric,
    desc_word
FROM first_part
UNION
SELECT
    order_number,
    identifier,
    category,
    total_paid,
    agg_metric,
    desc_word
FROM second_part
ORDER BY total_paid DESC
LIMIT 100
