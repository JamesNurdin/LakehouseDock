WITH order_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ws.ws_order_number,
        d_sold.d_date AS sold_date,
        p.p_promo_name,
        r.r_reason_desc,
        wp.wp_url,
        SUM(wr.wr_net_loss) AS order_net_loss
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_sold.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc = 'Did not like the warranty'
      AND wp.wp_link_count > 5
      AND cd_bill.cd_gender = 'M'
      AND ca_bill.ca_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        ws.ws_order_number,
        d_sold.d_date,
        p.p_promo_name,
        r.r_reason_desc,
        wp.wp_url
    HAVING SUM(wr.wr_net_loss) > 1000
)
SELECT
    o.s_store_id,
    o.s_store_name,
    o.ws_order_number,
    o.sold_date,
    o.p_promo_name,
    o.r_reason_desc,
    o.wp_url,
    o.order_net_loss,
    ROW_NUMBER() OVER (PARTITION BY o.s_store_id ORDER BY o.order_net_loss DESC) AS order_rank
FROM order_agg o
ORDER BY o.s_store_id, order_rank
LIMIT 100
