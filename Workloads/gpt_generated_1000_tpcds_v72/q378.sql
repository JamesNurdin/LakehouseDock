WITH sales_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        cs.cs_ext_sales_price        AS cs_sales,
        ss.ss_ext_sales_price        AS ss_sales,
        ws.ws_ext_sales_price        AS ws_sales,
        cr.cr_return_amount          AS cr_return,
        sr.sr_return_amt            AS sr_return,
        wr.wr_return_amt            AS wr_return,
        p.p_discount_active,
        r_cr.r_reason_desc          AS cr_reason_desc,
        r_sr.r_reason_desc          AS sr_reason_desc,
        r_wr.r_reason_desc          AS wr_reason_desc,
        w.w_warehouse_name,
        cc.cc_name,
        td_sold.t_hour               AS sold_hour,
        td_cr.t_hour                AS cr_return_hour,
        td_sr.t_hour                AS sr_return_hour,
        td_wr.t_hour                AS wr_return_hour,
        wp.wp_url,
        wsit.web_name,
        CASE WHEN (COALESCE(cs.cs_net_profit,0) + COALESCE(ss.ss_net_profit,0) + COALESCE(ws.ws_net_profit,0)) > 0
             THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM item i
    LEFT JOIN catalog_sales cs           ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss             ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws               ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr          ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN promotion p                ON p.p_item_sk = i.i_item_sk
    LEFT JOIN time_dim td_sold           ON td_sold.t_time_sk = cs.cs_sold_time_sk
    LEFT JOIN time_dim td_cr             ON td_cr.t_time_sk = cr.cr_returned_time_sk
    LEFT JOIN time_dim td_sr             ON td_sr.t_time_sk = sr.sr_return_time_sk
    LEFT JOIN time_dim td_wr             ON td_wr.t_time_sk = wr.wr_returned_time_sk
    LEFT JOIN warehouse w               ON w.w_warehouse_sk = cs.cs_warehouse_sk
    LEFT JOIN call_center cc            ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN customer_demographics cd  ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    LEFT JOIN reason r_cr               ON r_cr.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN reason r_sr               ON r_sr.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN reason r_wr               ON r_wr.r_reason_sk = wr.wr_reason_sk
    LEFT JOIN web_page wp               ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN web_site wsit              ON wsit.web_site_sk = ws.ws_web_site_sk
    WHERE EXISTS (
        SELECT 1 FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
)
SELECT
    i_category,
    i_brand,
    SUM(cs_sales)           AS total_catalog_sales,
    SUM(ss_sales)           AS total_store_sales,
    SUM(ws_sales)           AS total_web_sales,
    SUM(cr_return)          AS total_catalog_returns,
    SUM(sr_return)          AS total_store_returns,
    SUM(wr_return)          AS total_web_returns,
    SUM(cs_sales + ss_sales + ws_sales - cr_return - sr_return - wr_return) AS net_sales,
    CASE WHEN SUM(cs_sales + ss_sales + ws_sales - cr_return - sr_return - wr_return) > 0 THEN 'POS' ELSE 'NEG' END AS net_flag
FROM sales_data
GROUP BY ROLLUP (i_category, i_brand)
ORDER BY i_category, i_brand
LIMIT 100
