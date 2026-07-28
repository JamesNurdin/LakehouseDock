WITH base_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_size,
        i.i_manager_id,
        i.i_color,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        cs.cs_order_number,
        cs.cs_net_profit AS catalog_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_order_number,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        cc.cc_name,
        cc.cc_rec_start_date,
        sm.sm_type,
        wp.wp_type,
        wsite.web_name,
        cust.c_customer_id,
        ca.ca_city,
        ca.ca_county
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM item i
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT
    bs.i_category,
    bs.i_brand,
    bs.i_size,
    bs.p_promo_name,
    SUM(bs.catalog_net_profit) AS total_catalog_profit,
    SUM(bs.store_net_profit) AS total_store_profit,
    SUM(bs.web_net_profit) AS total_web_profit,
    SUM(ra.store_net_loss) AS total_store_net_loss,
    SUM(ra.catalog_net_loss) AS total_catalog_net_loss,
    SUM(ra.web_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT bs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT bs.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT bs.ws_order_number) AS web_orders,
    SUM(ra.store_return_cnt) AS total_store_returns,
    SUM(ra.catalog_return_cnt) AS total_catalog_returns,
    SUM(ra.web_return_cnt) AS total_web_returns
FROM base_sales bs
JOIN returns_agg ra ON ra.i_item_sk = bs.i_item_sk
WHERE bs.i_manager_id = 34
  AND bs.i_size = 'extra large'
  AND bs.p_discount_active = 'Y'
  AND bs.cc_name LIKE '%Call%'
  AND bs.sm_type = 'AIR'
  AND bs.ca_city = 'Fairfield'
  AND bs.cc_rec_start_date >= DATE '2001-01-01'
  AND bs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    bs.i_category,
    bs.i_brand,
    bs.i_size,
    bs.p_promo_name
HAVING SUM(bs.catalog_net_profit) > 10000
ORDER BY total_catalog_profit DESC
LIMIT 100
