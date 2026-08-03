WITH
store_enriched AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_sold_time_sk,
        t_s.t_hour,
        i.i_category,
        s.s_store_name,
        i.i_item_sk,
        ca_cust.ca_address_sk AS cust_addr_sk,
        cd_cust.cd_gender,
        hd_cust.hd_vehicle_count,
        ib.ib_upper_bound,
        p.p_discount_active,
        i_promo.i_brand
    FROM store_sales ss
    JOIN time_dim t_s
        ON ss.ss_sold_time_sk = t_s.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca_cust
        ON ss.ss_addr_sk = ca_cust.ca_address_sk
    JOIN customer_demographics cd_cust
        ON ss.ss_cdemo_sk = cd_cust.cd_demo_sk
    JOIN household_demographics hd_cust
        ON ss.ss_hdemo_sk = hd_cust.hd_demo_sk
    JOIN income_band ib
        ON hd_cust.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i_promo
        ON p.p_item_sk = i_promo.i_item_sk
),
web_enriched AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        t_w.t_hour,
        i_w.i_category,
        ca_ship.ca_city,
        cd_ship.cd_gender,
        hd_ship.hd_vehicle_count,
        ib_ship.ib_lower_bound,
        p_ship.p_discount_active
    FROM web_sales ws
    JOIN time_dim t_w
        ON ws.ws_sold_time_sk = t_w.t_time_sk
    JOIN item i_w
        ON ws.ws_item_sk = i_w.i_item_sk
    JOIN promotion p_ship
        ON ws.ws_promo_sk = p_ship.p_promo_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib_ship
        ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
)
SELECT
    COALESCE(se.s_store_name, 'WEB_ONLY') AS store_name,
    COALESCE(se.i_category, we.i_category) AS item_category,
    COALESCE(se.t_hour, we.t_hour) AS hour_of_day,
    SUM(COALESCE(se.ss_net_profit, 0)) AS total_store_net_profit,
    SUM(COALESCE(we.ws_net_profit, 0)) AS total_web_net_profit
FROM store_enriched se
FULL OUTER JOIN web_enriched we
    ON se.ss_item_sk = we.ws_item_sk
   AND se.ss_sold_time_sk = we.ws_sold_time_sk
WHERE se.ss_quantity > (
    SELECT MAX(ws_quantity)
    FROM web_sales
    WHERE ws_quantity < 1000
)
GROUP BY
    COALESCE(se.s_store_name, 'WEB_ONLY'),
    COALESCE(se.i_category, we.i_category),
    COALESCE(se.t_hour, we.t_hour)
ORDER BY total_store_net_profit DESC
LIMIT 100
