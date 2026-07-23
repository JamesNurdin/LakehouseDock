WITH joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ws.ws_ext_ship_cost,
        ws.ws_ext_sales_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_list_price,
        ws.ws_coupon_amt,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_paid_inc_ship,
        ws.ws_net_paid_inc_ship_tax,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        p.p_promo_sk,
        p.p_channel_radio,
        p.p_purpose,
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_type,
        sm.sm_contract,
        ws_site.web_site_sk,
        ws_site.web_name,
        t_ws.t_time_sk,
        t_ws.t_hour,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_refunded_cash,
        r.r_reason_sk,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        c_bill.c_customer_sk AS bill_customer_sk,
        c_ship.c_customer_sk AS ship_customer_sk,
        c_return.c_customer_sk AS return_customer_sk,
        hd_current.hd_demo_sk,
        hd_current.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ib.ib_income_band_sk,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'High' ELSE 'Low' END AS income_bracket
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN customer c_return ON sr.sr_customer_sk = c_return.c_customer_sk
    JOIN household_demographics hd_return ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN household_demographics hd_current ON c_bill.c_current_hdemo_sk = hd_current.hd_demo_sk
    JOIN income_band ib ON hd_current.hd_income_band_sk = ib.ib_income_band_sk
    WHERE p.p_channel_radio = 'N'
      AND sm.sm_carrier = 'FEDEX'
      AND ib.ib_lower_bound >= 80000
), agg_data AS (
    SELECT
        web_name,
        i_category,
        income_bracket,
        COUNT(DISTINCT bill_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT ship_customer_sk) AS distinct_ship_customers,
        SUM(ws_net_paid) AS total_sales,
        SUM(sr_return_amt) AS total_returns,
        SUM(ws_net_profit) - SUM(sr_return_amt) AS net_profit_after_returns,
        AVG(ws_ext_discount_amt) AS avg_discount,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM joined_data
    GROUP BY
        web_name,
        i_category,
        income_bracket
)
SELECT
    web_name,
    i_category,
    income_bracket,
    distinct_bill_customers,
    distinct_ship_customers,
    total_sales,
    total_returns,
    net_profit_after_returns,
    avg_discount,
    avg_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY web_name ORDER BY total_sales DESC) AS sales_rank_within_site,
    SUM(total_sales) OVER (PARTITION BY web_name) AS site_total_sales
FROM agg_data
ORDER BY total_sales DESC, web_name
LIMIT 100
