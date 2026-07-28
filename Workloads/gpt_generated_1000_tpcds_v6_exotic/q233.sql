WITH all_data AS (
    SELECT
        w.w_warehouse_id,
        w.w_country,
        w.w_state,
        i.i_item_id,
        i.i_brand,
        i.i_current_price,
        cp.cp_catalog_number,
        cp.cp_description,
        p.p_promo_name,
        p.p_discount_active,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_net_loss,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        wp.wp_type
    FROM warehouse w
    JOIN catalog_returns cr
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
     AND p.p_item_sk = i.i_item_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    WHERE w.w_country = 'United States'
      AND i.i_current_price > 20
      AND cp.cp_catalog_number BETWEEN 10 AND 20
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'home'
      AND ib.ib_upper_bound <= 80000
)
SELECT
    w_warehouse_id,
    w_country,
    i_brand,
    p_promo_name,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(store_net_loss) AS total_store_loss,
    SUM(web_net_loss) AS total_web_loss,
    COUNT(DISTINCT ws_order_number) AS orders_cnt,
    AVG(i_current_price) AS avg_price,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = all_data.i_brand) AS brand_avg_price,
    RANK() OVER (PARTITION BY w_country ORDER BY SUM(cr_return_amount) DESC) AS return_rank_by_country
FROM all_data
GROUP BY w_warehouse_id, w_country, i_brand, p_promo_name
HAVING SUM(cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
