-- Goal: Analyze combined store, catalog, and web sales and returns performance by item and promotion for Electronics, retaining promotions without sales, and showing inventory and web page info.
WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_promo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    COALESCE(SUM(sa.total_net_paid), 0) AS total_store_sales,
    COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt,
    SUM(inv.inv_quantity_on_hand) AS inventory_on_hand,
    MAX(wp.wp_url) AS sample_url
FROM sales_agg sa
RIGHT OUTER JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
LEFT OUTER JOIN item i
    ON p.p_item_sk = i.i_item_sk
LEFT OUTER JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
LEFT OUTER JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
WHERE i.i_category = 'Electronics'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = cs.cs_bill_customer_sk
          AND c.c_preferred_cust_flag = 'Y'
    )
GROUP BY i.i_item_id, i.i_product_name, p.p_promo_name
ORDER BY total_store_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
