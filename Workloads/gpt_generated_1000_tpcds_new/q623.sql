WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_promo_sk,
        ss_addr_sk,
        SUM(ss_net_paid) AS ss_total_net_paid,
        SUM(ss_quantity) AS ss_total_quantity,
        ARRAY[SUM(ss_quantity), SUM(ss_net_paid)] AS ss_metrics_arr
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_sold_time_sk, ss_promo_sk, ss_addr_sk
),
sr_agg AS (
    SELECT
        sr_store_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt) AS sr_total_return_amt,
        COUNT(*) AS sr_return_cnt
    FROM store_returns
    GROUP BY sr_store_sk, sr_returned_date_sk
),
cs_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_sold_time_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS cs_total_sales_price,
        SUM(cs_quantity) AS cs_total_quantity
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_order_number, cs_sold_time_sk, cs_ship_mode_sk, cs_warehouse_sk
),
cr_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_amount) AS cr_total_return_amount,
        COUNT(*) AS cr_return_cnt
    FROM catalog_returns
    GROUP BY cr_order_number
),
ws_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_web_site_sk,
        SUM(ws_net_paid) AS ws_total_net_paid,
        SUM(ws_quantity) AS ws_total_quantity
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_sold_time_sk, ws_web_site_sk
),
promo_common AS (
    SELECT p.p_promo_id
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE cs.cs_ext_sales_price > 1000
    INTERSECT
    SELECT p.p_promo_id
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE ws.ws_ext_sales_price > 1000
)
SELECT
    s.s_store_name,
    t.t_hour,
    p.p_promo_name,
    ss.ss_total_net_paid,
    sr.sr_total_return_amt,
    cs.cs_total_sales_price,
    cr.cr_total_return_amount,
    ws.ws_total_net_paid,
    ca.ca_city,
    sm.sm_carrier,
    w.w_warehouse_name,
    metric_value,
    (SELECT AVG(ss_total_net_paid) FROM ss_agg) AS avg_store_net_paid
FROM ss_agg ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_promo_id IN (SELECT p_promo_id FROM promo_common)
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN cs_agg cs
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN cr_agg cr
    ON cs.cs_order_number = cr.cr_order_number
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN sr_agg sr
    ON ss.ss_store_sk = sr.sr_store_sk
    AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
JOIN ws_agg ws
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
CROSS JOIN UNNEST(ss.ss_metrics_arr) AS u(metric_value)
WHERE s.s_country = 'United States'
  AND s.s_tax_percentage > 5.0
  AND t.t_hour BETWEEN 9 AND 17
  AND p.p_discount_active = 'Y'
  AND w.w_state = 'CA'
  AND sm.sm_type = 'AIR'
LIMIT 100
