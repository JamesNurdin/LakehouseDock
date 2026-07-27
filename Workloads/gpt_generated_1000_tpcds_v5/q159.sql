WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ship_customer_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_education_status,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        i.i_product_name,
        p.p_promo_name,
        sm.sm_type,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT
    s.cs_sold_date_sk,
    s.c_first_name,
    s.c_last_name,
    s.cd_education_status,
    s.hd_buy_potential,
    s.ib_upper_bound,
    s.i_product_name,
    s.p_promo_name,
    s.sm_type,
    s.profit_category,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_ext_sales_price) AS total_sales,
    SUM(s.cs_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_return_quantity) AS web_return_items
FROM sales_agg s
JOIN web_sales ws ON s.cs_item_sk = ws.ws_item_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
JOIN store_returns sr ON s.cs_item_sk = sr.sr_item_sk
JOIN store st ON sr.sr_store_sk = st.s_store_sk
-- reuse customer dimension for ship‑to customer
JOIN customer c_ship ON s.cs_ship_customer_sk = c_ship.c_customer_sk
-- ship‑to address
JOIN customer_address ca_ship ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
-- ship‑to demographics
JOIN customer_demographics cd_ship ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
GROUP BY
    s.cs_sold_date_sk,
    s.c_first_name,
    s.c_last_name,
    s.cd_education_status,
    s.hd_buy_potential,
    s.ib_upper_bound,
    s.i_product_name,
    s.p_promo_name,
    s.sm_type,
    s.profit_category
ORDER BY total_sales DESC
LIMIT 100
