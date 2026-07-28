WITH sales_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_sold_time_sk,
        ss.ss_net_profit AS store_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        CASE WHEN ws.ws_net_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        td.t_hour,
        i_ws.i_category,
        p_ws.p_promo_name AS ws_promo_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        c_ws.c_customer_id,
        c_cs.c_customer_id AS cs_customer_id,
        td_wr.t_hour AS return_hour,
        p_cs.p_promo_name AS cs_promo_name
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN store_sales ss ON ws.ws_sold_time_sk = ss.ss_sold_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON td.t_time_sk = cs.cs_sold_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd_cs ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN income_band ib ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN customer c_cs ON cs.cs_bill_customer_sk = c_cs.c_customer_sk
    JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
)
SELECT
    profit_category,
    t_hour,
    i_category,
    ws_promo_name,
    SUM(ws_net_profit) AS total_ws_profit,
    SUM(store_net_profit) AS total_store_profit,
    SUM(catalog_net_profit) AS total_catalog_profit,
    COUNT(DISTINCT ws_order_number) AS orders
FROM sales_base
GROUP BY GROUPING SETS (
    (profit_category, t_hour, i_category, ws_promo_name),
    (profit_category, t_hour, i_category),
    (profit_category, t_hour),
    (profit_category),
    ()
)
HAVING SUM(ws_net_profit) > 5000
ORDER BY total_ws_profit DESC
LIMIT 100
