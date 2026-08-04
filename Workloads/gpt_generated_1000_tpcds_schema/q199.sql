WITH
    cat AS (
        SELECT
            cs.cs_sold_date_sk AS date_key,
            cs.cs_sold_time_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_promo_sk,
            cs.cs_bill_addr_sk,
            cs.cs_bill_cdemo_sk
        FROM catalog_sales cs
        JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
        JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        WHERE d1.d_year = 2001
    ),
    web AS (
        SELECT
            ws.ws_sold_date_sk AS date_key,
            ws.ws_sold_time_sk,
            ws.ws_ship_mode_sk,
            ws.ws_promo_sk,
            ws.ws_ship_addr_sk,
            ws.ws_ship_cdemo_sk
        FROM web_sales ws
        JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
        JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
        JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        JOIN customer_address ca2 ON ws.ws_ship_addr_sk = ca2.ca_address_sk
        JOIN customer_demographics cd2 ON ws.ws_ship_cdemo_sk = cd2.cd_demo_sk
        WHERE d2.d_year = 2001
    ),
    common_dates AS (
        SELECT date_key FROM cat
        INTERSECT
        SELECT date_key FROM web
    )
SELECT
    d.d_year,
    p.p_promo_name,
    COUNT(*) AS store_sales_cnt,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    AVG(ws.ws_net_paid) AS avg_web_net_paid
FROM common_dates cd_int
JOIN store_sales ss ON ss.ss_sold_date_sk = cd_int.date_key
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = cd_int.date_key
GROUP BY d.d_year, p.p_promo_name
ORDER BY total_store_net_paid DESC
OFFSET 0 LIMIT 100
