WITH joined_data AS (
    SELECT
        cc.cc_name,
        d.d_year,
        cp.cp_department,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_net_loss AS web_return_net_loss,
        r.r_reason_desc
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND ib.ib_upper_bound > 50000
      AND ws.ws_ext_sales_price > 1000
      AND r.r_reason_desc LIKE '%defect%'
)
SELECT
    cc_name,
    d_year,
    cp_department,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(store_net_loss) AS total_store_loss,
    SUM(web_return_net_loss) AS total_web_return_loss,
    RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
FROM joined_data
GROUP BY cc_name, d_year, cp_department
ORDER BY sales_rank
LIMIT 100
