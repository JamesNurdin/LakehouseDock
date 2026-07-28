WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        cp.cp_department AS department,
        we.web_name AS web_site_name,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_returns_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_returns_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_returns_loss,
        COUNT(DISTINCT r_store.r_reason_sk) AS store_return_reason_cnt,
        COUNT(DISTINCT r_catalog.r_reason_sk) AS catalog_return_reason_cnt,
        COUNT(DISTINCT r_web.r_reason_sk) AS web_return_reason_cnt
    FROM
        time_dim td
        /* Store channel */
        LEFT JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
        LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
        LEFT JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
        LEFT JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
        LEFT JOIN income_band ib_store ON hd_store.hd_income_band_sk = ib_store.ib_income_band_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
        /* Catalog channel */
        LEFT JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
        LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN customer c_catalog ON cs.cs_bill_customer_sk = c_catalog.c_customer_sk
        LEFT JOIN customer_demographics cd_catalog ON cs.cs_bill_cdemo_sk = cd_catalog.cd_demo_sk
        LEFT JOIN household_demographics hd_catalog ON cs.cs_bill_hdemo_sk = hd_catalog.hd_demo_sk
        LEFT JOIN income_band ib_catalog ON hd_catalog.hd_income_band_sk = ib_catalog.ib_income_band_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                    AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN reason r_catalog ON cr.cr_reason_sk = r_catalog.r_reason_sk
        /* Web channel */
        LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
        LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN customer c_web ON ws.ws_bill_customer_sk = c_web.c_customer_sk
        LEFT JOIN customer_demographics cd_web ON ws.ws_bill_cdemo_sk = cd_web.cd_demo_sk
        LEFT JOIN household_demographics hd_web ON ws.ws_bill_hdemo_sk = hd_web.hd_demo_sk
        LEFT JOIN income_band ib_web ON hd_web.hd_income_band_sk = ib_web.ib_income_band_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    GROUP BY
        s.s_store_name,
        cp.cp_department,
        we.web_name
)
SELECT * FROM base
LIMIT 100
