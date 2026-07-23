WITH active_promos AS (
    SELECT DISTINCT p.p_promo_sk,
           p.p_promo_name,
           p.p_start_date_sk,
           p.p_end_date_sk,
           p.p_item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
ws_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        i.i_item_sk AS i_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        i.i_current_price,
        ap.p_promo_name,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        wp.wp_url,
        wp.wp_image_count,
        ws_site.web_name AS website_name,
        wh.w_warehouse_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN active_promos ap ON ws.ws_promo_sk = ap.p_promo_sk
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN date_dim d_promo_start ON ap.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON ap.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN date_dim d_ws_open ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
)
SELECT
    we.i_category,
    we.i_brand,
    we.p_promo_name,
    we.cd_gender,
    SUM(we.ws_ext_sales_price) AS total_sales,
    SUM(we.ws_net_profit) AS total_profit,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss,
    COUNT(DISTINCT we.ws_bill_customer_sk) AS distinct_customers,
    CASE
        WHEN SUM(we.ws_net_profit) > 50000 THEN 'High Profit'
        WHEN SUM(we.ws_net_profit) < 0 THEN 'Loss'
        ELSE 'Normal'
    END AS profit_category
FROM ws_enriched we
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = we.i_item_sk
    AND sr.sr_returned_date_sk = we.ws_sold_date_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = we.i_item_sk
    AND wr.wr_order_number = we.ws_order_number
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = we.ws_order_number
      AND wr2.wr_item_sk = we.i_item_sk
)
  AND we.i_current_price > 100
GROUP BY we.i_category, we.i_brand, we.p_promo_name, we.cd_gender
HAVING SUM(we.ws_ext_sales_price) > 10000
ORDER BY total_profit DESC
LIMIT 50
