WITH base AS (
    SELECT
        s.s_store_id,
        i.i_category,
        td_store.t_hour,
        r_sr.r_reason_desc,
        SUM(ss.ss_net_profit)                AS store_net_profit,
        SUM(cs.cs_net_profit)                AS catalog_net_profit,
        SUM(ws.ws_net_profit)                AS web_net_profit,
        SUM(sr.sr_net_loss)                  AS store_return_loss,
        SUM(cr.cr_net_loss)                  AS catalog_return_loss,
        SUM(wr.wr_net_loss)                  AS web_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number)  AS store_sales_cnt,
        COUNT(DISTINCT cs.cs_order_number)   AS catalog_sales_cnt,
        COUNT(DISTINCT ws.ws_order_number)   AS web_sales_cnt
    FROM store_sales       ss
    JOIN time_dim        td_store   ON ss.ss_sold_time_sk = td_store.t_time_sk
    JOIN item            i          ON ss.ss_item_sk = i.i_item_sk
    JOIN store           s          ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd    ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band     ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns   sr         ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason          r_sr       ON sr.sr_reason_sk = r_sr.r_reason_sk
    /* Catalog side */
    JOIN catalog_sales   cs         ON i.i_item_sk = cs.cs_item_sk
    JOIN time_dim        td_cat     ON cs.cs_sold_time_sk = td_cat.t_time_sk
    JOIN call_center     cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page    cp         ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode       sm_cat     ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
    JOIN warehouse       w_cat      ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
    JOIN catalog_returns cr        ON cs.cs_order_number = cr.cr_order_number
                                      AND cs.cs_item_sk = cr.cr_item_sk
    JOIN reason          r_cr       ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN time_dim        td_cr      ON cr.cr_returned_time_sk = td_cr.t_time_sk
    /* Web side */
    JOIN web_sales       ws         ON i.i_item_sk = ws.ws_item_sk
    JOIN time_dim        td_web     ON ws.ws_sold_time_sk = td_web.t_time_sk
    JOIN web_site        web        ON ws.ws_web_site_sk = web.web_site_sk
    JOIN ship_mode       sm_web     ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
    JOIN warehouse       w_web      ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
    JOIN web_returns     wr         ON ws.ws_order_number = wr.wr_order_number
                                      AND ws.ws_item_sk = wr.wr_item_sk
    JOIN reason          r_wr       ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN time_dim        td_wr      ON wr.wr_returned_time_sk = td_wr.t_time_sk
    /* Inventory */
    JOIN inventory       inv        ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse       w_inv      ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    WHERE
        td_store.t_hour BETWEEN 9 AND 17
        AND i.i_brand = 'Brand#23'
        AND s.s_state = 'TX'
        AND cc.cc_market_manager = 'John Doe'
        AND ib.ib_upper_bound > 50000
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_amount > 100
        )
    GROUP BY
        s.s_store_id,
        i.i_category,
        td_store.t_hour,
        r_sr.r_reason_desc
)
SELECT
    b.*,
    (SELECT SUM(ws2.ws_net_paid)
       FROM web_sales ws2
       JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
       WHERE i2.i_category = b.i_category) AS total_category_web_paid
FROM base b
ORDER BY b.store_net_profit DESC
LIMIT 100
