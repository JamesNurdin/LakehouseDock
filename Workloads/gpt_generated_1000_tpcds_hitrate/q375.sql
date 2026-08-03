WITH inv_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk, inv.inv_date_sk
)
SELECT
    d_cs.d_year,
    s.s_store_name,
    w.w_warehouse_name,
    wp.wp_type,
    SUM(cs.cs_net_profit) AS catalog_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    CASE
        WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH'
        ELSE 'LOW'
    END AS catalog_profit_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_profit) DESC) AS store_profit_rank
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer c_cs ON cs.cs_bill_customer_sk = c_cs.c_customer_sk
JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cs.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN inv_agg ia
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
    AND ia.inv_date_sk = d_cs.d_date_sk
WHERE d_cs.d_year = 2001
  AND w.w_state = 'CA'
  AND ca_cs.ca_country = 'United States'
  AND wp.wp_type = 'product'
  AND cs.cs_quantity > 5
  AND ss.ss_quantity > 5
GROUP BY CUBE (d_cs.d_year, s.s_store_name, w.w_warehouse_name, wp.wp_type)
ORDER BY catalog_profit DESC
LIMIT 100
