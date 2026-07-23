WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_return_amt AS wr_return_amt,
        wr.wr_net_loss AS wr_net_loss,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        i.i_brand_id,
        p.p_promo_name,
        cp.cp_department,
        s.s_store_name,
        s.s_division_name,
        s.s_gmt_offset,
        d.cd_gender,
        hd.hd_income_band_sk,
        t.t_hour,
        r.r_reason_desc
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics d ON ss.ss_cdemo_sk = d.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE s.s_division_name = 'Unknown'
        AND hd.hd_income_band_sk IN (7, 14)
        AND i.i_brand_id = 5
        AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    s_division_name,
    s_store_name,
    t_hour,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(wr_return_amt) AS total_web_returns,
    SUM(ss_net_profit) AS total_store_net_profit,
    SUM(cs_net_profit) AS total_catalog_net_profit,
    SUM(ws_net_profit) AS total_web_net_profit,
    SUM(CASE WHEN sr_net_loss > 0 THEN 1 ELSE 0 END) AS store_loss_count,
    SUM(CASE WHEN cr_net_loss > 0 THEN 1 ELSE 0 END) AS catalog_loss_count,
    SUM(CASE WHEN wr_net_loss > 0 THEN 1 ELSE 0 END) AS web_loss_count
FROM base
GROUP BY s_division_name, s_store_name, t_hour
ORDER BY total_store_sales DESC
