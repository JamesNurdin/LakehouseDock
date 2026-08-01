WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        ib.ib_lower_bound AS lower_income,
        ib.ib_upper_bound AS upper_income,
        td.t_hour AS hour_of_day,
        cs.cs_ext_sales_price AS catalog_sales_price,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_ext_sales_price AS store_sales_price,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_ext_sales_price AS web_sales_price,
        ws.ws_net_profit AS web_net_profit,
        COALESCE(wr.wr_net_loss, 0) AS web_return_loss,
        inv.inv_quantity_on_hand AS inv_quantity
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN household_demographics hd_store
        ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_rec_start_date BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND s.s_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_order_number = cs.cs_order_number
            AND cs2.cs_net_profit > 1000
      )
),
aggregated AS (
    SELECT
        store_name,
        promo_name,
        lower_income,
        upper_income,
        hour_of_day,
        SUM(catalog_sales_price) AS total_catalog_sales,
        SUM(store_sales_price) AS total_store_sales,
        SUM(web_sales_price) AS total_web_sales,
        SUM(web_return_loss) AS total_web_returns_loss,
        SUM(catalog_net_profit + store_net_profit + web_net_profit - web_return_loss) AS total_net_profit,
        (SELECT COUNT(*) FROM inventory WHERE inv_quantity_on_hand > 0) AS active_inventory_items
    FROM base
    GROUP BY store_name, promo_name, lower_income, upper_income, hour_of_day
    HAVING SUM(catalog_sales_price) > 10000
)
SELECT
    store_name,
    promo_name,
    lower_income,
    upper_income,
    hour_of_day,
    total_catalog_sales,
    total_store_sales,
    total_web_sales,
    total_web_returns_loss,
    total_net_profit,
    active_inventory_items,
    ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY total_net_profit DESC) AS promo_store_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
