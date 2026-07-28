WITH base AS (
    SELECT
        cc.cc_tax_percentage,
        s.s_manager,
        i.i_current_price,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        ib.ib_upper_bound,
        s.s_store_id,
        i.i_item_id,
        r_cr.r_reason_desc AS catalog_reason,
        r_sr.r_reason_desc AS store_reason,
        r_wr.r_reason_desc AS web_reason
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_ship ON ss.ss_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON ss.ss_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE cc.cc_tax_percentage > 0.05
      AND s.s_manager LIKE 'J%'
      AND i.i_current_price BETWEEN 10 AND 100
      AND cs.cs_ext_sales_price > 500
      AND cr.cr_return_amount > 1000
      AND ib.ib_upper_bound < 50000
),
catalog_agg AS (
    SELECT
        s_store_id,
        i_item_id,
        SUM(cs_ext_sales_price) AS sales,
        SUM(cr_return_amount) AS returns,
        'catalog' AS source
    FROM base
    GROUP BY s_store_id, i_item_id
),
store_agg AS (
    SELECT
        s_store_id,
        i_item_id,
        SUM(cs_ext_sales_price) AS sales,
        SUM(sr_return_amt) AS returns,
        'store' AS source
    FROM base
    GROUP BY s_store_id, i_item_id
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    s_store_id,
    i_item_id,
    source,
    SUM(sales) AS total_sales,
    SUM(returns) AS total_returns,
    CASE WHEN SUM(sales) = 0 THEN 0
         ELSE SUM(returns) / SUM(sales) END AS return_rate
FROM combined
GROUP BY ROLLUP (s_store_id, i_item_id, source)
ORDER BY total_sales DESC
LIMIT 100
