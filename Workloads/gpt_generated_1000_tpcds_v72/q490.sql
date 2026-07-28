WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_sales.d_year,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sales.d_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    -- join catalog sales and related tables
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk AND cs.cs_order_number = cr.cr_order_number
    -- join web sales and related tables
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
    LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    -- join store returns (optional) for reason data
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d_sales.d_year = 2001
      AND ib.ib_lower_bound >= 100000
      AND i.i_category = 'Sports'
      AND s.s_state = 'CA'
    GROUP BY s.s_store_sk, s.s_store_name, d_sales.d_year
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    s_store_sk,
    s_store_name,
    d_year,
    store_sales_profit,
    web_sales_profit,
    catalog_sales_profit,
    total_inventory_on_hand,
    (store_sales_profit + web_sales_profit + catalog_sales_profit) AS total_profit,
    RANK() OVER (ORDER BY (store_sales_profit + web_sales_profit + catalog_sales_profit) DESC) AS profit_rank,
    (SELECT COUNT(DISTINCT r_sub.r_reason_sk) FROM reason r_sub) AS total_reason_cnt
FROM sales_agg
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_store_sk = sales_agg.s_store_sk
      AND sr2.sr_reason_sk IN (
          SELECT r3.r_reason_sk FROM reason r3 WHERE r3.r_reason_desc LIKE '%price%'
      )
)
ORDER BY total_profit DESC
LIMIT 100
