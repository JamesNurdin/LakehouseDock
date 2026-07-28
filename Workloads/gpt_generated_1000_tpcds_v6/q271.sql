WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_web_page_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM tpcds.web_sales
    GROUP BY
        ws_item_sk,
        ws_sold_date_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_web_page_sk,
        ws_order_number
)
SELECT
    d_sold.d_year,
    s.s_store_name,
    p.p_promo_name,
    SUM(ws_agg.total_sales) AS total_sales,
    SUM(ws_agg.total_profit) AS total_profit,
    CASE
        WHEN SUM(ws_agg.total_profit) > 100000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    (
        SELECT AVG(inner_sales)
        FROM (
            SELECT ws_ext_sales_price AS inner_sales
            FROM tpcds.web_sales
        ) t
    ) AS avg_sale_price
FROM ws_agg
-- Join dimensions for the aggregated web sales
JOIN tpcds.date_dim d_sold ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.warehouse w ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN tpcds.web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk

-- Store‑return related joins (store, reason, customer, household, date)
LEFT JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN tpcds.reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN tpcds.customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
LEFT JOIN tpcds.date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk

-- Catalog‑return related joins (call_center, catalog_page, warehouse, reason, date, demographics)
LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN tpcds.warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
LEFT JOIN tpcds.reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN tpcds.date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN tpcds.customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN tpcds.customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk

-- Web‑return related joins (reason, web_page, date, demographics, and link back to aggregated sales)
LEFT JOIN tpcds.web_returns wr ON wr.wr_order_number = ws_agg.ws_order_number
LEFT JOIN tpcds.reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN tpcds.web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
LEFT JOIN tpcds.date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN tpcds.customer_demographics cd_refunded_wr ON wr.wr_refunded_cdemo_sk = cd_refunded_wr.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd_refunded_wr ON wr.wr_refunded_hdemo_sk = hd_refunded_wr.hd_demo_sk
LEFT JOIN tpcds.customer_demographics cd_returning_wr ON wr.wr_returning_cdemo_sk = cd_returning_wr.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd_returning_wr ON wr.wr_returning_hdemo_sk = hd_returning_wr.hd_demo_sk

GROUP BY ROLLUP (s.s_store_name, p.p_promo_name, d_sold.d_year)
ORDER BY total_profit DESC
LIMIT 100
