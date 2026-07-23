SELECT
    t.ws_order_number,
    t.ws_sold_date_sk,
    t.ws_ship_date_sk,
    t.ws_quantity,
    t.ws_list_price,
    t.ws_net_profit,
    t.p_promo_name,
    t.p_discount_active,
    t.sm_type,
    t.sm_code,
    t.w_warehouse_name,
    t.web_name,
    t.bill_city,
    t.ship_city,
    t.hd_buy_potential,
    t.hd_vehicle_count,
    t.ib_lower_bound,
    t.ib_upper_bound,
    t.profit_rank
FROM (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_net_profit,
        p.p_promo_name,
        p.p_discount_active,
        p.p_end_date_sk,
        sm.sm_type,
        sm.sm_code,
        w.w_warehouse_name,
        site.web_name,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        hd_bill.hd_buy_potential,
        hd_ship.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY site.web_name ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_list_price > 20
      AND ws.ws_net_profit > 0
      AND p.p_end_date_sk > 2450500
) t
WHERE t.profit_rank <= 10
ORDER BY t.web_name, t.profit_rank
LIMIT 100
