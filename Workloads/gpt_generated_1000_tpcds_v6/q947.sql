/*
Goal: Rank items by total sales across catalog, store, and web channels, showing inventory level, discount classification, and performance tier while filtering on company, market, price, ship mode, state, income band, and business hours.
*/
WITH base AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_ext_sales_price          AS catalog_sales,
        cs.cs_net_profit               AS catalog_profit,
        ss.ss_ext_sales_price          AS store_sales,
        ss.ss_net_profit               AS store_profit,
        ws.ws_ext_sales_price          AS web_sales,
        ws.ws_net_profit               AS web_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        i.i_item_sk,
        p.p_discount_active,
        cc.cc_company_name,
        s.s_market_id,
        sm.sm_type,
        ca.ca_state,
        ib.ib_upper_bound,
        td.t_hour,
        CASE
            WHEN cs.cs_ext_discount_amt > 100 THEN 'High Discount'
            ELSE 'Low Discount'
        END                           AS discount_level
    FROM tpcds.catalog_sales cs
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_sold_time_sk = cs.cs_sold_time_sk
        AND ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_time_sk = cs.cs_sold_time_sk
        AND ws.ws_item_sk = cs.cs_item_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_company_name = 'Unknown'
      AND s.s_market_id IN (1, 3, 5)
      AND i.i_current_price BETWEEN 10 AND 500
      AND sm.sm_type = 'AIR'
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND td.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        cs_item_sk,
        i_item_id,
        i_product_name,
        i_category,
        i_brand,
        discount_level,
        SUM(COALESCE(catalog_sales, 0) + COALESCE(store_sales, 0) + COALESCE(web_sales, 0)) AS total_sales,
        SUM(COALESCE(catalog_profit, 0) + COALESCE(store_profit, 0) + COALESCE(web_profit, 0)) AS total_profit
    FROM base
    GROUP BY cs_item_sk, i_item_id, i_product_name, i_category, i_brand, discount_level
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.i_category,
    a.i_brand,
    a.total_sales,
    a.total_profit,
    (
        SELECT AVG(inv_quantity_on_hand)
        FROM tpcds.inventory inv
        WHERE inv.inv_item_sk = a.cs_item_sk
    ) AS avg_inventory_qty,
    DENSE_RANK() OVER (PARTITION BY a.i_category ORDER BY a.total_sales DESC) AS category_rank,
    CASE
        WHEN a.total_sales > 100000 THEN 'Top Performer'
        ELSE 'Regular'
    END AS performance_tier,
    a.discount_level
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
