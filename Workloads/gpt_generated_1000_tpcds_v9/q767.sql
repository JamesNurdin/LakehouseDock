WITH base_agg AS (
    SELECT
        s.s_store_id,
        d.d_quarter_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS store_return_loss,
        COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_return_loss,
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit)
         - COALESCE(SUM(sr.sr_net_loss), 0) - COALESCE(SUM(cr.cr_net_loss), 0)) AS total_profit,
        COUNT(*) AS transaction_count
    FROM
        date_dim d
        JOIN store s
            ON s.s_closed_date_sk = d.d_date_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_store_sk = s.s_store_sk
        JOIN customer_address ca
            ON ca.ca_address_sk = ss.ss_addr_sk
        JOIN customer_demographics cd
            ON cd.cd_demo_sk = ss.ss_cdemo_sk
        JOIN household_demographics hd
            ON hd.hd_demo_sk = ss.ss_hdemo_sk
        JOIN income_band ib
            ON ib.ib_income_band_sk = hd.hd_income_band_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN catalog_page cp
            ON cp.cp_start_date_sk = d.d_date_sk
            AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
        JOIN web_site w
            ON w.web_open_date_sk = d.d_date_sk
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_web_site_sk = w.web_site_sk
        JOIN store_returns sr
            ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_store_sk = s.s_store_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r
            ON r.r_reason_sk = sr.sr_reason_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
            AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            AND cr.cr_reason_sk = r.r_reason_sk
        JOIN inventory inv
            ON inv.inv_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND cp.cp_department = 'Books'
        AND sm.sm_type = 'AIR'
        AND ca.ca_state = 'CA'
        AND ib.ib_lower_bound >= 50000
    GROUP BY
        ROLLUP(s.s_store_id, d.d_quarter_name)
)

SELECT
    b.s_store_id,
    b.d_quarter_name,
    b.total_profit,
    b.transaction_count,
    (SELECT AVG(total_profit) FROM base_agg) AS avg_total_profit_all
FROM base_agg b
WHERE b.total_profit > (SELECT AVG(total_profit) FROM base_agg)
ORDER BY b.total_profit DESC
LIMIT 100
