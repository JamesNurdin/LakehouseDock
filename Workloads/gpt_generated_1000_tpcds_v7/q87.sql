WITH agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'TX'
      AND cc.cc_division = 3
      AND w.w_country = 'United States'
      AND ss.ss_quantity > 5
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    s_store_id,
    d_year,
    total_net_profit,
    total_return_loss,
    transaction_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    CASE WHEN total_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_indicator
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100
