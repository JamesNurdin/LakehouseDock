WITH
    -- alias date_dim for various roles
    d_cs_sold AS (SELECT * FROM date_dim),
    d_cs_ship AS (SELECT * FROM date_dim),
    d_promo_start AS (SELECT * FROM date_dim),
    d_promo_end AS (SELECT * FROM date_dim),
    d_sr_return AS (SELECT * FROM date_dim),
    d_ws_sold AS (SELECT * FROM date_dim),
    d_ws_ship AS (SELECT * FROM date_dim),
    d_wp_creation AS (SELECT * FROM date_dim),
    d_wp_access AS (SELECT * FROM date_dim),
    d_we_open AS (SELECT * FROM date_dim),
    d_we_close AS (SELECT * FROM date_dim),
    d_wr_returned AS (SELECT * FROM date_dim)
SELECT
    i_cs.i_category                                            AS category,
    d_cs_sold.d_year                                           AS year,
    SUM(cs.cs_net_paid)                                        AS catalog_sales_net,
    SUM(ws.ws_net_paid)                                        AS web_sales_net,
    SUM(sr.sr_return_amt)                                      AS store_return_amount,
    SUM(wr.wr_return_amt)                                      AS web_return_amount,
    COUNT(DISTINCT cs.cs_order_number)                         AS num_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number)                         AS num_web_orders
FROM
    catalog_sales cs
    JOIN d_cs_sold          ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN d_cs_ship          ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN item i_cs          ON cs.cs_item_sk = i_cs.i_item_sk
    JOIN promotion p        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN d_promo_start     ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN d_promo_end       ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib     ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    -- store returns and its dimensions
    JOIN store_returns sr   ON sr.sr_item_sk = i_cs.i_item_sk
                           AND sr.sr_cdemo_sk = cd_bill.cd_demo_sk
                           AND sr.sr_hdemo_sk = hd_bill.hd_demo_sk
    JOIN store s            ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN d_sr_return       ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    -- web sales and its dimensions
    JOIN web_sales ws       ON ws.ws_item_sk = i_cs.i_item_sk
                           AND ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
                           AND ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN d_ws_sold         ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN d_ws_ship         ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN web_page wp        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN d_wp_creation     ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN d_wp_access       ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN d_we_open         ON we.web_open_date_sk = d_we_open.d_date_sk
    JOIN d_we_close        ON we.web_close_date_sk = d_we_close.d_date_sk
    -- web returns and its dimensions
    JOIN web_returns wr     ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = i_cs.i_item_sk
    JOIN d_wr_returned    ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    JOIN reason r_wr        ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_page wp_wr      ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE
    d_cs_sold.d_year = 2001
    AND i_cs.i_category = 'Books'
GROUP BY
    ROLLUP (i_cs.i_category, d_cs_sold.d_year)
ORDER BY
    category,
    year
LIMIT 100
