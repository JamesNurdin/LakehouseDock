WITH aggregated AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        we.web_site_sk,
        we.web_name,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_paid)               AS total_store_sales,
        SUM(sr.sr_net_loss)               AS total_store_returns,
        SUM(ws.ws_net_paid)               AS total_web_sales,
        SUM(wr.wr_net_loss)               AS total_web_returns,
        SUM(inv.inv_quantity_on_hand)    AS total_inventory_on_hand
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                          AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE i.i_current_price > 100
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND w.w_gmt_offset >= -5
      AND we.web_country = 'United States'
    GROUP BY s.s_store_sk, s.s_store_name,
             we.web_site_sk, we.web_name,
             i.i_item_sk, i.i_product_name
)
SELECT
    AVG(total_store_sales + total_web_sales - total_store_returns - total_web_returns) AS avg_net_profit,
    SUM(total_inventory_on_hand) AS total_inventory,
    COUNT(DISTINCT s_store_sk) AS distinct_store_count
FROM aggregated
WHERE total_store_sales > 10000
  AND total_web_sales > 5000
  AND (total_store_sales + total_web_sales) > 20000
HAVING COUNT(*) > 0
LIMIT 100
