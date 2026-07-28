SELECT
    cp.cp_department,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    CASE
        WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS catalog_sales_category
FROM
    catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN store_sales ss
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
        AND hd.hd_demo_sk = ss.ss_hdemo_sk
    INNER JOIN web_sales ws
        ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
        AND hd.hd_demo_sk = ws.ws_bill_hdemo_sk
    INNER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
WHERE
    cp.cp_department = 'Sports'
    AND sm.sm_type = 'AIR'
    AND ib.ib_lower_bound >= 50000
    AND cs.cs_quantity > 5
    AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_order_number = cs.cs_order_number
    )
GROUP BY
    GROUPING SETS (
        (cp.cp_department, sm.sm_type),
        (cp.cp_department, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound)
    )
ORDER BY
    catalog_profit DESC
LIMIT 100
