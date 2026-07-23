WITH aggregated AS (
    SELECT
        w.web_city AS web_city,
        td.t_hour AS t_hour,
        p.p_promo_name AS p_promo_name,
        sm.sm_type AS sm_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MIN(ws.ws_ext_sales_price) AS min_sales_price,
        MAX(ws.ws_ext_sales_price) AS max_sales_price
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_hour = 14
      AND cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND w.web_city = 'Springfield'
      AND ws.ws_quantity > 5
      AND ws.ws_net_paid > 1000
      AND c.c_birth_year = 1975
      AND cd.cd_gender = 'M'
      AND r.r_reason_desc = 'Damaged'
    GROUP BY w.web_city, td.t_hour, p.p_promo_name, sm.sm_type
)
SELECT
    web_city,
    t_hour,
    p_promo_name,
    sm_type,
    total_net_paid,
    avg_discount_amount,
    distinct_orders,
    min_sales_price,
    max_sales_price,
    ROW_NUMBER() OVER (PARTITION BY web_city ORDER BY total_net_paid DESC) AS city_net_paid_rank,
    (SELECT AVG(ws2.ws_ext_discount_amt) FROM web_sales ws2) AS overall_avg_discount_amt
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
