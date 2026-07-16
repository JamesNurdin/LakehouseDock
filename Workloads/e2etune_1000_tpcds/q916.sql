WITH store_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        s.s_store_id AS store_id,
        cd.cd_gender AS gender,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY p.p_promo_id, s.s_store_id, cd.cd_gender
    HAVING SUM(ss.ss_ext_sales_price) > 10000
),
web_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        w.web_site_id AS site_id,
        cd.cd_gender AS gender,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451000 AND 2452000
    GROUP BY p.p_promo_id, w.web_site_id, cd.cd_gender
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
    promo_id,
    channel,
    location_id,
    gender,
    distinct_customers,
    total_sales,
    total_profit,
    total_discount,
    avg_discount
FROM (
    SELECT
        promo_id,
        'store' AS channel,
        store_id AS location_id,
        gender,
        distinct_customers,
        total_sales,
        total_profit,
        total_discount,
        avg_discount
    FROM store_agg
    UNION ALL
    SELECT
        promo_id,
        'web' AS channel,
        site_id AS location_id,
        gender,
        distinct_customers,
        total_sales,
        total_profit,
        total_discount,
        avg_discount
    FROM web_agg
) combined
ORDER BY total_sales DESC
LIMIT 100
