WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cc.cc_name,
        cp.cp_department,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        sm.sm_type,
        w.w_warehouse_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        d_cs.d_year,
        ss.ss_net_paid_inc_tax,
        ws.ws_net_paid,
        ws.ws_ship_customer_sk,
        wr.wr_return_amt
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    LEFT JOIN customer_demographics cd_wr
        ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    LEFT JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    WHERE d_cs.d_year = 2001
      AND ws.ws_ship_customer_sk IN (7530658, 9482918)
      AND i.i_current_price > 500
      AND sm.sm_type = 'AIR'
      AND cr.cr_return_quantity > 0
)
SELECT
    d_year,
    i_category,
    SUM(COALESCE(cs_net_paid, 0)) AS total_catalog_sales,
    SUM(COALESCE(ws_net_paid, 0)) AS total_web_sales,
    SUM(COALESCE(ss_net_paid_inc_tax, 0)) AS total_store_sales,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns,
    COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
    MIN(COALESCE(cs_net_paid, ws_net_paid, ss_net_paid_inc_tax)) AS min_sales_amount,
    MAX(COALESCE(cs_net_paid, ws_net_paid, ss_net_paid_inc_tax)) AS max_sales_amount
FROM base
GROUP BY CUBE(d_year, i_category)
ORDER BY d_year ASC NULLS LAST, i_category ASC NULLS LAST
LIMIT 100
