WITH joined_data AS (
    SELECT
        cc.cc_call_center_id,
        s.s_store_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_ext_sales_price AS catalog_sales_price,
        ss.ss_ext_sales_price AS store_sales_price,
        ws.ws_ext_sales_price AS web_sales_price,
        cs.cs_net_profit AS catalog_profit,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit,
        cs.cs_sales_price,
        cs.cs_quantity,
        ss.ss_quantity AS store_quantity,
        ws.ws_quantity AS web_quantity,
        cs.cs_ship_customer_sk,
        ss.ss_customer_sk,
        ws.ws_bill_customer_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c_bill.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_web ON wp.wp_customer_sk = c_web.c_customer_sk
    WHERE hd_bill.hd_dep_count >= 2
      AND hd_bill.hd_vehicle_count >= 0
      AND cs.cs_sales_price > 5.00
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound <= 70000
),
agg_data AS (
    SELECT
        cc_call_center_id,
        s_store_id,
        ib_lower_bound,
        ib_upper_bound,
        SUM(catalog_sales_price) AS total_catalog_sales,
        SUM(store_sales_price) AS total_store_sales,
        SUM(web_sales_price) AS total_web_sales,
        SUM(catalog_profit + store_profit + web_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY cc_call_center_id, s_store_id, ib_lower_bound, ib_upper_bound
    HAVING SUM(catalog_profit + store_profit + web_profit) > 10000
)
SELECT
    cc_call_center_id,
    s_store_id,
    ib_lower_bound,
    ib_upper_bound,
    total_catalog_sales,
    total_store_sales,
    total_web_sales,
    total_profit,
    txn_count,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_profit DESC) AS profit_rank_by_store
FROM agg_data
ORDER BY total_profit DESC
LIMIT 100
