/* Goal:  Analyze total sales and return loss across catalog, store, and web channels by customer and item, showing subtotals and a row number per customer. */
WITH base AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        d_sold.d_date AS sale_date,
        cs.cs_net_paid                AS catalog_sales_net,
        ss.ss_net_paid                AS store_sales_net,
        ws.ws_net_paid                AS web_sales_net,
        cr.cr_net_loss                AS catalog_return_loss,
        sr.sr_net_loss                AS store_return_loss,
        wr.wr_net_loss                AS web_return_loss
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_sold               ON cs.cs_sold_time_sk = t_sold.t_time_sk
    INNER JOIN item i                       ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p                  ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN customer c                   ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN ship_mode sm                 ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w                  ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN catalog_returns cr           ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN reason r_cr                  ON cr.cr_reason_sk = r_cr.r_reason_sk
    /* Second date dimension for the return date (optional, demonstrates a second join to the same table) */
    INNER JOIN date_dim d_ret                ON cr.cr_returned_date_sk = d_ret.d_date_sk
    /* Store side */
    INNER JOIN store_sales ss               ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN date_dim d_store_sold         ON ss.ss_sold_date_sk = d_store_sold.d_date_sk
    INNER JOIN time_dim t_store_sold         ON ss.ss_sold_time_sk = t_store_sold.t_time_sk
    INNER JOIN store_returns sr             ON sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN reason r_sr                  ON sr.sr_reason_sk = r_sr.r_reason_sk
    /* Web side */
    INNER JOIN web_sales ws                 ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN date_dim d_web_sold           ON ws.ws_sold_date_sk = d_web_sold.d_date_sk
    INNER JOIN time_dim t_web_sold           ON ws.ws_sold_time_sk = t_web_sold.t_time_sk
    INNER JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN web_site webs                ON ws.ws_web_site_sk = webs.web_site_sk
    INNER JOIN web_returns wr               ON wr.wr_order_number = ws.ws_order_number
    INNER JOIN reason r_wr                  ON wr.wr_reason_sk = r_wr.r_reason_sk
)
SELECT
    c_customer_id,
    i_item_id,
    sale_date,
    SUM(catalog_sales_net)   AS total_catalog_sales,
    SUM(store_sales_net)     AS total_store_sales,
    SUM(web_sales_net)       AS total_web_sales,
    SUM(catalog_return_loss) AS total_catalog_return_loss,
    SUM(store_return_loss)   AS total_store_return_loss,
    SUM(web_return_loss)     AS total_web_return_loss,
    COUNT(*)                 AS transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY sale_date) AS rn
FROM base
GROUP BY GROUPING SETS (
    (c_customer_id, i_item_id, sale_date),
    (c_customer_id, i_item_id),
    (c_customer_id),
    (i_item_id),
    ()
)
ORDER BY c_customer_id, i_item_id
LIMIT 100
