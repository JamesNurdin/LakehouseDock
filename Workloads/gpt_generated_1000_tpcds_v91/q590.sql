-- Goal: Calculate total net profit by promotion, warehouse and customer demographics for a sampled set of catalog sales,
-- integrating store and web sales, applying promotion channel and demographic filters, and reporting the top results.
WITH base AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_catalog,
        p.p_channel_demo,
        p.p_end_date_sk,
        sm_cs.sm_ship_mode_id,
        sm_cs.sm_contract,
        w.w_warehouse_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_ext_sales_price AS cs_sales,
        cs.cs_net_profit AS cs_profit,
        ss.ss_ext_sales_price AS ss_sales,
        ss.ss_net_profit AS ss_profit,
        ws.ws_ext_sales_price AS ws_sales,
        ws.ws_net_profit AS ws_profit,
        COALESCE(sr.sr_net_loss, 0) AS sr_loss,
        r.r_reason_desc
    FROM
        (SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)) AS cs
        JOIN time_dim AS td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
        JOIN promotion AS p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode AS sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN warehouse AS w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer_demographics AS cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics AS hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        -- store_sales
        JOIN store_sales AS ss ON ss.ss_promo_sk = p.p_promo_sk
        JOIN time_dim AS td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
        JOIN customer_demographics AS cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics AS hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        -- web_sales
        JOIN web_sales AS ws ON ws.ws_promo_sk = p.p_promo_sk
        JOIN time_dim AS td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN ship_mode AS sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN customer_demographics AS cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
        JOIN household_demographics AS hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
        JOIN web_page AS wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        -- store_returns (optional)
        LEFT JOIN store_returns AS sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN time_dim AS td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
        LEFT JOIN reason AS r ON sr.sr_reason_sk = r.r_reason_sk
        -- inventory (optional)
        LEFT JOIN inventory AS inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT
    p_promo_id,
    p_promo_name,
    w_warehouse_name,
    sm_ship_mode_id,
    cd_gender,
    cd_marital_status,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    SUM(cs_sales) AS total_catalog_sales,
    SUM(ss_sales) AS total_store_sales,
    SUM(ws_sales) AS total_web_sales,
    SUM(cs_profit + ss_profit + ws_profit - sr_loss) AS total_net_profit,
    COUNT(DISTINCT p_promo_id) AS distinct_promotions,
    COUNT(DISTINCT w_warehouse_name) AS distinct_warehouses
FROM base
WHERE
    p_channel_catalog = 'N'
    AND p_channel_demo = 'N'
    AND p_end_date_sk BETWEEN 2450100 AND 2450200
    AND sm_contract = 'P7FBIt8yd'
    AND cd_dep_count >= 3
    AND hd_buy_potential = 'HIGH'
GROUP BY
    p_promo_id,
    p_promo_name,
    w_warehouse_name,
    sm_ship_mode_id,
    cd_gender,
    cd_marital_status,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound
HAVING
    SUM(cs_profit + ss_profit + ws_profit - sr_loss) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
