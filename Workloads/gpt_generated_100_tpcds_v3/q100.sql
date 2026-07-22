WITH inventory_summary AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    w.w_warehouse_name,
    inv_sum.total_quantity_on_hand,
    SUM(ss.ss_net_profit) AS store_sales_net_profit,
    SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_returns_net_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_returns_net_loss,
    (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) AS total_net_profit,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) DESC) AS profit_rank,
    CASE
        WHEN (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) >
             (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_average,
    COUNT(DISTINCT r.r_reason_desc) AS store_return_reason_count,
    COUNT(DISTINCT r2.r_reason_desc) AS web_return_reason_count
FROM store_sales ss
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = t.t_time_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   AND cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_summary inv_sum
    ON inv_sum.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_return_time_sk = t.t_time_sk
   AND sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
   AND sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
   AND wp.wp_web_page_sk = wr.wr_web_page_sk
LEFT JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE t.t_shift = 'first'
  AND ca.ca_state = 'CA'
  AND ib.ib_upper_bound > 50000
GROUP BY
    s.s_store_id,
    s.s_store_name,
    w.w_warehouse_name,
    inv_sum.total_quantity_on_hand
ORDER BY total_net_profit DESC
LIMIT 100
