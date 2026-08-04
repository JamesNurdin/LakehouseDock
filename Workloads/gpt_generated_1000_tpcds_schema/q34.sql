WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        p.p_promo_name,
        ws.ws_net_paid,
        td.t_hour
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws
      ON p.p_promo_sk = ws.ws_promo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
      ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
    WHERE s.s_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    ss_sold_date_sk,
    s_store_id,
    s_store_name,
    ca_city,
    cd_gender,
    hd_buy_potential,
    ib_upper_bound,
    p_promo_name,
    ws_net_paid,
    SUM(ws_net_paid) OVER (PARTITION BY s_store_id) AS store_total_sales,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY ws_net_paid DESC) AS rn
FROM joined_data
ORDER BY store_total_sales DESC, rn ASC
LIMIT 100
