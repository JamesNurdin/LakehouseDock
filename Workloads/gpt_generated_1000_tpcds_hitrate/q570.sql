WITH base AS (
    SELECT
        d_ws.d_year,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        p.p_promo_name,
        sm.sm_type AS ship_mode_type,
        ws.ws_net_paid,
        ss.ss_net_paid AS store_net_paid,
        CASE
            WHEN ws.ws_net_paid > ss.ss_net_paid THEN 'WEB'
            WHEN ws.ws_net_paid < ss.ss_net_paid THEN 'STORE'
            ELSE 'EQUAL'
        END AS higher_channel,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_net_paid DESC) AS web_rank
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_ws.d_date_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wb ON ws.ws_web_site_sk = wb.web_site_sk
    WHERE d_ws.d_year = 2001
      AND i.i_current_price > 20
      AND ca.ca_country = 'United States'
      AND sm.sm_type = 'AIR'
),
high_web AS (
    SELECT
        i_item_id,
        d_year,
        SUM(ws_net_paid) AS total_web_paid
    FROM base
    WHERE higher_channel = 'WEB'
    GROUP BY i_item_id, d_year
),
low_store AS (
    SELECT
        i_item_id,
        d_year,
        0.0 AS total_web_paid
    FROM base
    WHERE higher_channel = 'STORE' AND store_net_paid < 100
),
filtered AS (
    SELECT
        h.i_item_id,
        h.d_year,
        h.total_web_paid,
        CASE WHEN h.total_web_paid > 500 THEN 'HIGH' ELSE 'MEDIUM' END AS sales_level,
        ROW_NUMBER() OVER (PARTITION BY h.d_year ORDER BY h.total_web_paid DESC) AS rank_year
    FROM (
        SELECT i_item_id, d_year, total_web_paid FROM high_web
        EXCEPT
        SELECT i_item_id, d_year, total_web_paid FROM low_store
    ) h
)
SELECT
    f.i_item_id,
    f.d_year,
    f.total_web_paid,
    f.sales_level,
    f.rank_year,
    (SELECT SUM(total_web_paid) FROM high_web) AS overall_web_total
FROM filtered f
WHERE f.total_web_paid > 200
ORDER BY f.total_web_paid DESC
LIMIT 100
