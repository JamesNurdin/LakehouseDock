WITH combined_facts AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS item_category,
        td.t_hour AS hour_of_day,
        ss.ss_net_paid AS net_sales,
        CAST(0 AS decimal(7,2)) AS net_returns,
        CAST(0 AS decimal(7,2)) AS catalog_returns_amount,
        CAST(0 AS decimal(7,2)) AS web_sales_net_paid
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN item i_desc ON ss.ss_item_sk = i_desc.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    SELECT
        s.s_store_name AS store_name,
        i.i_category AS item_category,
        td.t_hour AS hour_of_day,
        CAST(0 AS decimal(7,2)) AS net_sales,
        sr.sr_net_loss AS net_returns,
        CAST(0 AS decimal(7,2)) AS catalog_returns_amount,
        CAST(0 AS decimal(7,2)) AS web_sales_net_paid
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN item i_price ON sr.sr_item_sk = i_price.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk

    UNION ALL

    SELECT
        NULL AS store_name,
        i.i_category AS item_category,
        td.t_hour AS hour_of_day,
        CAST(0 AS decimal(7,2)) AS net_sales,
        CAST(0 AS decimal(7,2)) AS net_returns,
        cr.cr_return_amount AS catalog_returns_amount,
        CAST(0 AS decimal(7,2)) AS web_sales_net_paid
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
    JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk

    UNION ALL

    SELECT
        NULL AS store_name,
        i.i_category AS item_category,
        td.t_hour AS hour_of_day,
        CAST(0 AS decimal(7,2)) AS net_sales,
        CAST(0 AS decimal(7,2)) AS net_returns,
        CAST(0 AS decimal(7,2)) AS catalog_returns_amount,
        ws.ws_net_paid AS web_sales_net_paid
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN item i_desc ON ws.ws_item_sk = i_desc.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
)
SELECT
    store_name,
    item_category,
    hour_of_day,
    SUM(net_sales) AS total_store_sales,
    SUM(net_returns) AS total_store_returns,
    SUM(catalog_returns_amount) AS total_catalog_returns,
    SUM(web_sales_net_paid) AS total_web_sales
FROM combined_facts
GROUP BY ROLLUP (store_name, item_category, hour_of_day)
ORDER BY store_name, item_category, hour_of_day
