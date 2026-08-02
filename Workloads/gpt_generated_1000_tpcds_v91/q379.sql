WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        s.s_state,
        ca.ca_state,
        i.i_brand,
        i.i_current_price,
        i.i_item_sk,
        p_ss.p_discount_active AS store_discount_active,
        p_ws.p_discount_active AS web_discount_active,
        sr.sr_net_loss,
        ws.ws_net_profit,
        ws.ws_quantity,
        wr.wr_net_loss,
        we.web_state,
        wp.wp_web_page_sk,
        w.w_warehouse_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
)
SELECT *
FROM (
    SELECT
        jd.s_state AS store_state,
        jd.ca_state AS address_state,
        jd.i_brand AS brand,
        jd.web_state AS web_state,
        SUM(jd.ss_net_profit) AS total_store_profit,
        SUM(jd.ws_net_profit) AS total_web_profit,
        CAST(NULL AS decimal(7,2)) AS total_store_return_loss,
        CAST(NULL AS decimal(7,2)) AS total_web_return_loss,
        COUNT(*) AS transaction_count,
        CAST(NULL AS bigint) AS return_transaction_count,
        (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = jd.i_brand) AS max_brand_price,
        CAST(NULL AS decimal(7,2)) AS min_brand_price
    FROM joined_data jd
    WHERE
        jd.i_current_price > 50
        AND jd.ca_state = 'CA'
        AND jd.s_state = 'CA'
        AND COALESCE(jd.store_discount_active, jd.web_discount_active) = 'Y'
        AND jd.ss_net_profit > 0
        AND jd.ws_net_profit > 0
        AND jd.i_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 5)
    GROUP BY CUBE (jd.s_state, jd.ca_state, jd.i_brand, jd.web_state)

    UNION ALL

    SELECT
        jd.s_state AS store_state,
        jd.ca_state AS address_state,
        jd.i_brand AS brand,
        jd.web_state AS web_state,
        CAST(NULL AS decimal(7,2)) AS total_store_profit,
        CAST(NULL AS decimal(7,2)) AS total_web_profit,
        SUM(jd.sr_net_loss) AS total_store_return_loss,
        SUM(jd.wr_net_loss) AS total_web_return_loss,
        CAST(NULL AS bigint) AS transaction_count,
        COUNT(*) AS return_transaction_count,
        CAST(NULL AS decimal(7,2)) AS max_brand_price,
        (SELECT MIN(i2.i_current_price) FROM item i2 WHERE i2.i_brand = jd.i_brand) AS min_brand_price
    FROM joined_data jd
    WHERE
        jd.sr_net_loss > 0
        AND jd.wr_net_loss > 0
        AND jd.i_current_price > 50
        AND jd.ca_state = 'CA'
        AND jd.s_state = 'CA'
    GROUP BY CUBE (jd.s_state, jd.ca_state, jd.i_brand, jd.web_state)
) AS combined
ORDER BY store_state, address_state, brand, web_state
