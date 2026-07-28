WITH joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        p.p_purpose AS p_purpose,
        p.p_channel_radio AS p_channel_radio,
        p.p_channel_email AS p_channel_email,
        hd.hd_vehicle_count AS hd_vehicle_count,
        hd.hd_buy_potential AS hd_buy_potential,
        s.s_state AS s_state,
        cc.cc_name AS cc_name,
        wp.wp_type AS wp_type,
        web_site.web_name AS web_name
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND p.p_channel_radio = 'Y'
      AND hd.hd_vehicle_count = 2
      AND i.i_current_price BETWEEN 50 AND 200
)
SELECT
    i_category,
    i_brand,
    s_state,
    p_purpose,
    COUNT(DISTINCT ss_sold_date_sk) AS days_sold,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(cr_return_amount) AS total_returns,
    AVG(ss_quantity) AS avg_store_quantity,
    RANK() OVER (ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
FROM joined
GROUP BY i_category, i_brand, s_state, p_purpose
ORDER BY total_store_sales DESC
LIMIT 100
