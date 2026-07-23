WITH sr_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY sr.sr_item_sk
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    GROUP BY ws.ws_item_sk
),
wr_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wr.wr_item_sk
)
SELECT
    i.i_category,
    i.i_brand,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    COALESCE(sr_agg.total_store_return_amt, 0) AS total_store_return_amt,
    COALESCE(sr_agg.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(ws_agg.total_web_sales, 0) AS total_web_sales,
    COALESCE(ws_agg.web_order_cnt, 0) AS web_order_cnt,
    COALESCE(wr_agg.total_web_return_amt, 0) AS total_web_return_amt,
    COALESCE(wr_agg.web_return_cnt, 0) AS web_return_cnt,
    (SELECT SUM(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS total_promo_cost
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN sr_agg ON i.i_item_sk = sr_agg.sr_item_sk
LEFT JOIN ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
LEFT JOIN wr_agg ON i.i_item_sk = wr_agg.wr_item_sk
WHERE cs.cs_quantity > 5
  AND cs.cs_net_paid > 1000
  AND cs.cs_ext_discount_amt < 200
  AND cc.cc_division = 4
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
GROUP BY
    i.i_category,
    i.i_brand,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    sr_agg.total_store_return_amt,
    sr_agg.store_return_cnt,
    ws_agg.total_web_sales,
    ws_agg.web_order_cnt,
    wr_agg.total_web_return_amt,
    wr_agg.web_return_cnt,
    i.i_item_sk
ORDER BY total_sales DESC
LIMIT 100
