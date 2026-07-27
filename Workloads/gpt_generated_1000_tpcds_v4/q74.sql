WITH joined AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        s.s_store_name,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ss.ss_ext_sales_price AS store_sales_price,
        ss.ss_net_profit AS store_net_profit,
        sr.sr_return_amt,
        ws.ws_ext_sales_price AS web_sales_price,
        ws.ws_net_profit AS web_net_profit,
        wr.wr_return_amt AS web_return_amt,
        wp.wp_type
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
    i_item_id,
    i_product_name,
    cp_department,
    sm_type,
    w_warehouse_name,
    cd_gender,
    hd_buy_potential,
    s_store_name,
    r_reason_desc,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(store_sales_price) AS total_store_sales,
    SUM(web_sales_price) AS total_web_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(web_return_amt) AS total_web_returns,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM joined
WHERE
    cp_department = 'Sports'               -- predicate 1
    AND sm_type = 'AIR'                     -- predicate 2
    AND w_warehouse_name LIKE '%Central%'  -- predicate 3
    AND cd_gender = 'M'                     -- predicate 4
    AND hd_buy_potential = '5000-10000'    -- predicate 5
    AND s_store_name IS NOT NULL           -- predicate 6
    AND i_item_id IN (SELECT i_item_id FROM item WHERE i_current_price > 100)  -- subquery predicate
GROUP BY
    i_item_id,
    i_product_name,
    cp_department,
    sm_type,
    w_warehouse_name,
    cd_gender,
    hd_buy_potential,
    s_store_name,
    r_reason_desc
HAVING SUM(cs_ext_sales_price) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
