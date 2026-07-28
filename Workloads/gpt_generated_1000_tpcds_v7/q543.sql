WITH sales_agg AS (
    SELECT
        s.s_store_id,
        wsite.web_site_id,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        i.i_item_id,
        td.t_hour,
        SUM(
            COALESCE(ss.ss_net_profit, 0) +
            COALESCE(cs.cs_net_profit, 0) +
            COALESCE(ws.ws_net_profit, 0)
        ) AS total_profit,
        COUNT(DISTINCT COALESCE(ss.ss_ticket_number, cs.cs_order_number, ws.ws_order_number)) AS txn_count
    FROM
        store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wsite
            ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        s.s_market_desc LIKE '%Financial%'
        AND cc.cc_gmt_offset BETWEEN -5 AND 5
        AND i.i_current_price > 50
        AND ib.ib_upper_bound >= 100000
        AND wp.wp_type = 'Content'
        AND wsite.web_country = 'United States'
    GROUP BY
        s.s_store_id,
        wsite.web_site_id,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        i.i_item_id,
        td.t_hour
)
SELECT
    s_store_id,
    web_site_id,
    cc_call_center_id,
    cp_catalog_page_id,
    i_item_id,
    t_hour,
    total_profit,
    txn_count,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    CASE
        WHEN total_profit > 100000 THEN 'High'
        WHEN total_profit > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_agg
ORDER BY profit_rank
LIMIT 20
