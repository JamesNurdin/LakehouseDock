WITH
    -- Central fact table
    ss AS (
        SELECT
            ss_sold_date_sk,
            ss_customer_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_addr_sk,
            ss_promo_sk,
            ss_ticket_number,
            ss_ext_sales_price,
            ss_net_profit
        FROM store_sales
    ),
    -- Returns linked to sales
    sr AS (
        SELECT
            sr_ticket_number,
            sr_return_amt,
            sr_reason_sk
        FROM store_returns
    ),
    -- Web sales (second fact) linked to the same customer dimensions
    ws AS (
        SELECT
            ws_order_number,
            ws_bill_customer_sk,
            ws_ship_hdemo_sk,
            ws_ship_addr_sk,
            ws_promo_sk,
            ws_net_profit
        FROM web_sales
    )
SELECT
    c.c_customer_id,
    ca_cur.ca_city               AS customer_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound            AS income_band_lower,
    p_sale.p_promo_name          AS sales_promo_name,
    SUM(ss.ss_ext_sales_price)   AS total_store_sales,
    SUM(sr.sr_return_amt)        AS total_store_returns,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(ws.ws_net_profit)        AS total_web_profit
FROM ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca_cur
    ON c.c_current_addr_sk = ca_cur.ca_address_sk
JOIN promotion p_sale
    ON ss.ss_promo_sk = p_sale.p_promo_sk
JOIN sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion p_web
    ON ws.ws_promo_sk = p_web.p_promo_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND ca_cur.ca_state = 'CA'
GROUP BY
    c.c_customer_id,
    ca_cur.ca_city,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    p_sale.p_promo_name
ORDER BY total_store_sales DESC
LIMIT 100
