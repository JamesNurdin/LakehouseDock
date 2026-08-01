WITH sales_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d_sold.d_date AS sold_date,
        d_sold.d_year AS sold_year,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cust.c_customer_sk,
        cust.c_customer_id,
        cust.c_first_name,
        cust.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        addr.ca_city AS address_city,
        addr.ca_state AS address_state,
        promo.p_promo_name,
        promo.p_discount_active,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_sales_price AS ws_sales_price,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        sm.sm_type AS ship_mode_type,
        wp.wp_url,
        wr.wr_returned_date_sk,
        wr.wr_return_amt AS web_return_amt,
        inv.inv_quantity_on_hand AS inventory_qty,
        cc.cc_name AS call_center_name
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN customer cust ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address addr ON ss.ss_addr_sk = addr.ca_address_sk
    JOIN promotion promo ON ss.ss_promo_sk = promo.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
        AND ws.ws_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
)
SELECT
    sd.c_customer_id,
    sd.c_first_name,
    sd.c_last_name,
    sd.cd_gender,
    sd.cd_marital_status,
    sd.hd_buy_potential,
    sd.address_city,
    sd.address_state,
    sd.sold_date,
    sd.ss_net_paid,
    sd.ss_net_profit,
    CASE WHEN sd.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    sd.inventory_qty,
    sd.call_center_name,
    ROW_NUMBER() OVER (PARTITION BY sd.c_customer_id ORDER BY sd.ss_net_paid DESC) AS rn_customer,
    RANK() OVER (ORDER BY sd.ss_net_profit DESC) AS profit_rank
FROM sales_data sd
WHERE
    sd.sold_year = 2001
    AND sd.cd_marital_status = 'M'
    AND sd.hd_buy_potential = '5001-10000'
    AND sd.address_state = 'CA'
    AND sd.p_discount_active = 'Y'
    AND sd.ws_quantity > 0
    AND sd.c_customer_id IN (
        SELECT DISTINCT c_customer_id
        FROM customer
        WHERE c_birth_country = 'United States'
    )
ORDER BY sd.ss_net_paid DESC, sd.c_customer_id
LIMIT 100
