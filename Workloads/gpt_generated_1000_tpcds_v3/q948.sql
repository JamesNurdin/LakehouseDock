WITH cs_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
    FROM catalog_sales cs
    GROUP BY
        cs.cs_order_number,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
)
SELECT
    t.dept,
    t.catalog_page_id,
    t.warehouse_name,
    t.promo_name,
    t.store_name,
    t.ship_mode_type,
    t.profit_status,
    t.total_sales_price,
    t.total_returns_amount,
    t.total_store_sales,
    t.total_web_sales,
    t.total_inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY t.dept ORDER BY t.total_sales_price DESC) AS dept_sales_rank
FROM (
    SELECT
        cp.cp_department AS dept,
        cp.cp_catalog_page_id AS catalog_page_id,
        w_sales.w_warehouse_name AS warehouse_name,
        p_sales.p_promo_name AS promo_name,
        s.s_store_name AS store_name,
        sm_sales.sm_type AS ship_mode_type,
        cs_agg.profit_status,
        SUM(cs_agg.total_sales_price) AS total_sales_price,
        SUM(cr.cr_return_amount) AS total_returns_amount,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM cs_agg
    JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs_agg.cs_catalog_page_sk
    JOIN promotion p_sales ON p_sales.p_promo_sk = cs_agg.cs_promo_sk
    JOIN warehouse w_sales ON w_sales.w_warehouse_sk = cs_agg.cs_warehouse_sk
    JOIN ship_mode sm_sales ON sm_sales.sm_ship_mode_sk = cs_agg.cs_ship_mode_sk
    JOIN household_demographics hd_bill ON hd_bill.hd_demo_sk = cs_agg.cs_bill_hdemo_sk
    JOIN household_demographics hd_ship ON hd_ship.hd_demo_sk = cs_agg.cs_ship_hdemo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs_agg.cs_order_number
    LEFT JOIN reason r_cr ON r_cr.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN ship_mode sm_return ON sm_return.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN warehouse w_return ON w_return.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN household_demographics hd_refunded ON hd_refunded.hd_demo_sk = cr.cr_refunded_hdemo_sk
    LEFT JOIN household_demographics hd_returning ON hd_returning.hd_demo_sk = cr.cr_returning_hdemo_sk
    LEFT JOIN store_sales ss ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN store s ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN promotion p_store ON p_store.p_promo_sk = ss.ss_promo_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN ship_mode sm_ws ON sm_ws.sm_ship_mode_sk = ws.ws_ship_mode_sk
    LEFT JOIN warehouse w_ws ON w_ws.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN promotion p_ws ON p_ws.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr ON r_wr.r_reason_sk = wr.wr_reason_sk
    LEFT JOIN household_demographics hd_wr_refund ON hd_wr_refund.hd_demo_sk = wr.wr_refunded_hdemo_sk
    LEFT JOIN household_demographics hd_wr_returning ON hd_wr_returning.hd_demo_sk = wr.wr_returning_hdemo_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w_sales.w_warehouse_sk
    GROUP BY
        cp.cp_department,
        cp.cp_catalog_page_id,
        w_sales.w_warehouse_name,
        p_sales.p_promo_name,
        s.s_store_name,
        sm_sales.sm_type,
        cs_agg.profit_status
) t
ORDER BY t.total_sales_price DESC
LIMIT 100
