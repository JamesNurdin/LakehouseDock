WITH joined_data AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        ss.ss_net_profit            AS store_profit,
        cs.cs_net_profit            AS catalog_profit,
        ws.ws_net_profit            AS web_profit,
        sr.sr_net_loss              AS store_return_loss,
        cr.cr_net_loss              AS catalog_return_loss,
        wr.wr_net_loss              AS web_return_loss
    FROM date_dim d
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory i
      ON i.inv_date_sk = d.d_date_sk
    JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 0
      AND ss.ss_quantity > 0
)
SELECT
    jd.p_promo_id,
    jd.d_year,
    SUM(jd.store_profit + jd.catalog_profit + jd.web_profit) AS total_profit,
    AVG(jd.store_profit)                                   AS avg_store_profit,
    COUNT(*)                                               AS rows_cnt,
    (SELECT COUNT(*) FROM inventory inv2 WHERE inv2.inv_quantity_on_hand > 100) AS high_stock_inventory_cnt
FROM joined_data jd
GROUP BY jd.p_promo_id, jd.d_year
HAVING SUM(jd.store_profit + jd.catalog_profit + jd.web_profit) > 10000
ORDER BY total_profit DESC
LIMIT 10
