WITH ss_chain AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        i.i_item_sk,
        i.i_item_id,
        i.i_class,
        i.i_brand,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        s.s_store_id,
        s.s_city,
        s.s_state
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND i.i_class = 'fragrances'
      AND p.p_discount_active = 'Y'
      AND ss.ss_net_paid > 1000
      AND i.i_color = 'Unknown'
)
SELECT
    sc.s_store_id,
    sc.s_city,
    sc.i_class,
    sc.p_promo_name,
    SUM(sc.ss_net_paid) AS store_sales_net_paid,
    COUNT(DISTINCT sc.ss_ticket_number) AS store_transactions,
    SUM(ws.ws_net_paid) AS web_sales_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    MIN(ws.ws_net_paid) AS web_min_net_paid,
    MAX(ws.ws_net_paid) AS web_max_net_paid
FROM ss_chain sc
JOIN web_sales ws
    ON ws.ws_item_sk = sc.i_item_sk
   AND ws.ws_promo_sk = sc.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_autogen_flag = 'N'
  AND wp.wp_access_date_sk = 2452629
  AND wp.wp_type = 'home'
GROUP BY sc.s_store_id, sc.s_city, sc.i_class, sc.p_promo_name
ORDER BY store_sales_net_paid DESC
LIMIT 100
