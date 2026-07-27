/*
Goal: Compute per‑store profitability by aggregating net profit from store sales, catalog sales and web sales, subtracting losses from store and catalog returns, and then keep only stores whose overall profit margin exceeds 15 %. The query joins all 16 TPC‑DS tables using only the permitted join keys, applies at least five filter predicates, uses an EXISTS semi‑join on the web_site table, aggregates in a CTE and re‑aggregates in the outer query, and limits the result to the top 100 stores.
*/
WITH base AS (
    SELECT
        s.s_store_id,
        ss.ss_net_profit               AS store_net_profit,
        cs.cs_net_profit               AS catalog_net_profit,
        ws.ws_net_profit               AS web_net_profit,
        sr.sr_net_loss                 AS store_return_loss,
        cr.cr_net_loss                 AS catalog_return_loss,
        cd.cd_education_status,
        hd.hd_buy_potential,
        ib.ib_upper_bound              AS income_upper,
        cc.cc_tax_percentage           AS cc_tax,
        s.s_tax_percentage             AS store_tax,
        ws_site.web_name
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs
        ON cs.cs_order_number = ss.ss_ticket_number
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        s.s_tax_percentage > 0.05
        AND cc.cc_tax_percentage < 0.09
        AND cd.cd_education_status = 'Advanced Degree'
        AND ib.ib_upper_bound >= 50000
        AND ws.ws_net_profit > 0
        AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = ws_site.web_site_sk
              AND ws2.ws_net_profit > 1000
        )
)
SELECT
    s_store_id,
    SUM(store_net_profit)          AS total_store_profit,
    SUM(catalog_net_profit)        AS total_catalog_profit,
    SUM(web_net_profit)            AS total_web_profit,
    SUM(store_return_loss)         AS total_store_return_loss,
    SUM(catalog_return_loss)       AS total_catalog_return_loss,
    (SUM(store_net_profit) + SUM(catalog_net_profit) + SUM(web_net_profit) -
     SUM(store_return_loss) - SUM(catalog_return_loss)) /
    NULLIF(SUM(store_net_profit) + SUM(catalog_net_profit) + SUM(web_net_profit), 0) AS profit_margin
FROM base
GROUP BY s_store_id
HAVING (SUM(store_net_profit) + SUM(catalog_net_profit) + SUM(web_net_profit) -
        SUM(store_return_loss) - SUM(catalog_return_loss)) /
       NULLIF(SUM(store_net_profit) + SUM(catalog_net_profit) + SUM(web_net_profit), 0) > 0.15
ORDER BY profit_margin DESC
LIMIT 100
