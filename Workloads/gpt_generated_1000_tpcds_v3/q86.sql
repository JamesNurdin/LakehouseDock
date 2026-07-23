WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_sold_time_sk,
        SUM(cs_net_paid) AS cs_sum_net_paid,
        SUM(cs_ext_discount_amt) AS cs_sum_discount,
        COUNT(*) AS cs_order_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_ext_sales_price > 0
      AND cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY
        cs_item_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_sold_time_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    cc.cc_name AS call_center_name,
    cp.cp_catalog_page_number,
    t.t_hour,
    cs_agg.cs_sum_net_paid,
    cs_agg.cs_order_cnt,
    SUM(ss.ss_net_paid) AS store_sum_net_paid,
    SUM(ws.ws_net_paid) AS web_sum_net_paid,
    (cs_agg.cs_sum_net_paid + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) AS total_net_paid,
    CASE
        WHEN cs_agg.cs_sum_net_paid > (SELECT AVG(cs_net_paid) FROM catalog_sales) THEN 'Above Avg Catalog'
        ELSE 'Below Avg Catalog'
    END AS catalog_sales_perf,
    CASE
        WHEN (cs_agg.cs_sum_net_paid + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) > 50000 THEN 'High'
        ELSE 'Low'
    END AS total_sales_category
FROM cs_agg
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t
    ON cs_agg.cs_sold_time_sk = t.t_time_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_item_sk = i.i_item_sk
   AND ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_promo_sk = p.p_promo_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_brand_id = 5
    AND p.p_channel_email = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_catalog_page_number,
    t.t_hour,
    cs_agg.cs_sum_net_paid,
    cs_agg.cs_order_cnt
HAVING
    (cs_agg.cs_sum_net_paid + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) > 100000
ORDER BY
    total_net_paid DESC
LIMIT 100
