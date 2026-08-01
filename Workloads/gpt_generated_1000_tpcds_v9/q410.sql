WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        web_site.web_site_id,
        web_site.web_name,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit,
        ws.ws_wholesale_cost,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        web_site.web_mkt_class,
        web_site.web_street_name,
        web_site.web_state
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE hd.hd_buy_potential LIKE '%1000%'
      AND hd.hd_dep_count >= 2
      AND regexp_like(web_site.web_mkt_class, '(?i)rural|wide')
      AND web_site.web_street_name LIKE '%Main%'
      AND substr(web_site.web_state, 1, 2) = 'MI'
)
SELECT
    ss.ws_web_site_sk,
    ss.web_site_id,
    ss.web_name,
    COUNT(DISTINCT ss.ws_order_number) AS distinct_orders,
    SUM(ss.ws_net_paid_inc_ship_tax) AS total_sales,
    AVG(ss.ws_net_profit) AS avg_profit,
    MIN(ss.ws_net_profit) AS min_profit,
    MAX(ss.ws_net_profit) AS max_profit,
    MIN(CONCAT(CAST(ss.ws_order_number AS VARCHAR), '-', ss.web_site_id)) AS sample_order_site_key,
    (SELECT MAX(ws2.ws_wholesale_cost)
     FROM web_sales ws2
     WHERE ws2.ws_web_site_sk = ss.ws_web_site_sk) AS max_wholesale_cost
FROM site_sales ss
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws3
    WHERE ws3.ws_web_site_sk = ss.ws_web_site_sk
      AND ws3.ws_wholesale_cost > 70
)
GROUP BY ss.ws_web_site_sk, ss.web_site_id, ss.web_name
HAVING SUM(ss.ws_net_paid_inc_ship_tax) > 10000
ORDER BY total_sales DESC
LIMIT 100
