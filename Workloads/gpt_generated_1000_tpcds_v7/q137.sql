/*
  Goal: Produce an aggregated view of store performance that combines sales amounts, discount, store returns, catalog returns and web returns per store (identified by store_id and division) and sales hour. The query joins all selected tables, re‑uses the time_dim table under three different aliases and also joins the store table twice under different aliases to achieve at least nine join clauses. Results are ordered by total sales amount and limited to the top 100 rows.
*/
SELECT
    s.s_store_id,
    s.s_division_id,
    td_sales.t_hour AS sales_hour,
    td_catalog.t_hour AS catalog_return_hour,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_involved
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk                                   -- join rule 1
JOIN time_dim td_sales
  ON ss.ss_sold_time_sk = td_sales.t_time_sk                         -- join rule 2
JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
 AND ss.ss_item_sk = sr.sr_item_sk
 AND ss.ss_store_sk = sr.sr_store_sk                                 -- join rules 3,4,5
JOIN store s2
  ON sr.sr_store_sk = s2.s_store_sk                                   -- second alias for store (extra join)
JOIN time_dim td_returns
  ON sr.sr_return_time_sk = td_returns.t_time_sk                     -- join rule 6
JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = td_returns.t_time_sk                    -- join rule 7
JOIN time_dim td_catalog
  ON cr.cr_returned_time_sk = td_catalog.t_time_sk                    -- second alias for time_dim (extra join)
JOIN web_returns wr
  ON wr.wr_returned_time_sk = td_returns.t_time_sk                    -- join rule 8
JOIN time_dim td_web
  ON wr.wr_returned_time_sk = td_web.t_time_sk                        -- third alias for time_dim (extra join)
JOIN web_page wp
  ON wp.wp_web_page_sk = wr.wr_web_page_sk                            -- join rule 9
GROUP BY
    s.s_store_id,
    s.s_division_id,
    td_sales.t_hour,
    td_catalog.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
