WITH daily_metrics AS (
    SELECT
        d.d_date,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(COALESCE(-sr.sr_net_loss, 0)) AS store_return_recover,
        SUM(COALESCE(-wr.wr_net_loss, 0)) AS web_return_recover,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT s.s_store_sk) AS store_cnt,
        COUNT(DISTINCT wi.web_site_sk) AS web_site_cnt
    FROM date_dim d
    LEFT JOIN store_sales ss               ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store s                      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr            ON sr.sr_returned_date_sk = d.d_date_sk
                                         AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_sales cs            ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws                ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr              ON wr.wr_returned_date_sk = d.d_date_sk
                                         AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN inventory inv               ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w                 ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN web_site wi                 ON wi.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN web_page wp                 ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN time_dim t                  ON t.t_time_sk = ss.ss_sold_time_sk
    LEFT JOIN customer_address ca         ON ca.ca_address_sk = ss.ss_addr_sk
    WHERE d.d_year = 2022
      AND s.s_tax_percentage > 0.05
      AND w.w_gmt_offset BETWEEN -5 AND 5
      AND cs.cs_list_price > 100
      AND wp.wp_link_count > 5
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp.cp_department = 'Sports'
      )
    GROUP BY d.d_date
)
SELECT AVG(total_profit) AS avg_daily_profit
FROM (
    SELECT (store_profit + catalog_profit + web_profit + store_return_recover + web_return_recover) AS total_profit
    FROM daily_metrics
    WHERE (store_profit + catalog_profit + web_profit + store_return_recover + web_return_recover) > 1000
) t
LIMIT 100
