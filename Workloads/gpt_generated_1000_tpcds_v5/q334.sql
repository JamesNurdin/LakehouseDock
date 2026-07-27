WITH store_agg AS (
    SELECT
        ss_promo_sk,
        ss_sold_time_sk,
        COUNT(*) AS store_txn_cnt,
        SUM(ss_ext_sales_price) AS store_sales_total,
        AVG(ss_ext_discount_amt) AS avg_store_discount
    FROM store_sales
    WHERE ss_ext_tax > 100
      AND ss_sales_price BETWEEN 30 AND 70
    GROUP BY ss_promo_sk, ss_sold_time_sk
)
SELECT
    p.p_promo_id,
    t.t_hour,
    wsit.web_name,
    s.store_txn_cnt,
    s.store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    s.avg_store_discount,
    MAX(ws.ws_ext_discount_amt) AS max_web_discount,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM store_agg s
JOIN promotion p
    ON s.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON s.ss_sold_time_sk = t.t_time_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE p.p_channel_event = 'N'
  AND p.p_response_target = 1
  AND t.t_hour = 14
  AND wp.wp_type = 'Content'
  AND wsit.web_state = 'CA'
GROUP BY
    p.p_promo_id,
    t.t_hour,
    wsit.web_name,
    s.store_txn_cnt,
    s.store_sales_total,
    s.avg_store_discount
ORDER BY
    s.store_sales_total DESC
LIMIT 100
