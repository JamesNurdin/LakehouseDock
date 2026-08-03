/*
Goal: Compare high‑value billing and shipping customers by distinct order count, distinct sales amount and profit, enriched with demographic gender label and web‑site information, using a UNION ALL of two filtered groups.
*/
WITH sales_agg AS (
    SELECT
        ws_bill_customer_sk AS bill_customer_sk,
        ws_ship_customer_sk AS ship_customer_sk,
        ws_web_site_sk,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        SUM(DISTINCT ws_ext_sales_price) AS distinct_sales,
        SUM(ws_net_profit) AS total_profit,
        MAX(ws_coupon_amt) AS max_coupon
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_ship_customer_sk, ws_web_site_sk
)
SELECT
    c.c_customer_id,
    cd.cd_gender,
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
    agg.distinct_orders,
    agg.distinct_sales,
    agg.total_profit,
    agg.max_coupon,
    site.web_name AS site_name,
    (
        SELECT AVG(ws_inner.ws_ext_discount_amt)
        FROM web_sales ws_inner
        WHERE ws_inner.ws_web_site_sk = agg.ws_web_site_sk
    ) AS avg_site_discount
FROM sales_agg agg
JOIN customer c ON c.c_customer_sk = agg.bill_customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN web_site site ON site.web_site_sk = agg.ws_web_site_sk
WHERE agg.distinct_orders > 5
  AND site.web_market_manager LIKE '%Manager%'

UNION ALL

SELECT
    c2.c_customer_id,
    cd2.cd_gender,
    CASE WHEN cd2.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
    agg2.distinct_orders,
    agg2.distinct_sales,
    agg2.total_profit,
    agg2.max_coupon,
    site2.web_name AS site_name,
    (
        SELECT AVG(ws_inner2.ws_ext_discount_amt)
        FROM web_sales ws_inner2
        WHERE ws_inner2.ws_web_site_sk = agg2.ws_web_site_sk
    ) AS avg_site_discount
FROM sales_agg agg2
JOIN customer c2 ON c2.c_customer_sk = agg2.ship_customer_sk
JOIN customer_demographics cd2 ON cd2.cd_demo_sk = c2.c_current_cdemo_sk
JOIN web_site site2 ON site2.web_site_sk = agg2.ws_web_site_sk
WHERE agg2.distinct_sales > 10000
  AND site2.web_mkt_desc LIKE '%animals%'

ORDER BY total_profit DESC
LIMIT 100
