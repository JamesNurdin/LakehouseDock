/*
  Goal: Compute yearly profit per store, enrich it with related return losses from store, catalog and web returns, and rank stores by profit. The query joins all 16 selected TPC‑DS tables using the defined surrogate‑key relationships, re‑uses the DATE_DIM table under three different aliases and the WAREHOUSE table under two aliases, includes a scalar sub‑query to filter only stores with more than 100 sales transactions, and adds a ranking window function.
*/
WITH qualifying_stores AS (
    SELECT ss2.ss_store_sk
    FROM store_sales ss2
    GROUP BY ss2.ss_store_sk
    HAVING COUNT(*) > 100
)
SELECT
    s.s_store_id,
    d_year,
    SUM(ss.ss_net_paid)                         AS total_sales,
    SUM(ss.ss_net_profit)                       AS total_profit,
    COALESCE(SUM(sr.sr_net_loss), 0)            AS store_return_loss,
    COALESCE(SUM(cr.cr_net_loss), 0)            AS catalog_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0)            AS web_return_loss,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN date_dim d                       ON ss.ss_sold_date_sk      = d.d_date_sk               -- store‑sales date
JOIN store s                           ON ss.ss_store_sk         = s.s_store_sk               -- store
JOIN promotion p                       ON ss.ss_promo_sk         = p.p_promo_sk               -- promotion used in the sale
JOIN household_demographics hd_sales   ON ss.ss_hdemo_sk        = hd_sales.hd_demo_sk        -- buyer household
JOIN customer_address ca_sales        ON ss.ss_addr_sk         = ca_sales.ca_address_sk     -- buyer address

-- Catalog sales related to the same item and date (joined via item key and date)
LEFT JOIN catalog_sales cs               ON cs.cs_item_sk       = ss.ss_item_sk
                                       AND cs.cs_sold_date_sk  = d.d_date_sk
LEFT JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w_cat                ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
LEFT JOIN promotion p_cat                ON cs.cs_promo_sk      = p_cat.p_promo_sk
LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN customer_address ca_bill      ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
LEFT JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN customer_address ca_ship       ON cs.cs_ship_addr_sk   = ca_ship.ca_address_sk

-- Returns that can be tied back to the sale
LEFT JOIN store_returns sr               ON sr.sr_ticket_number = ss.ss_ticket_number
                                       AND sr.sr_store_sk      = s.s_store_sk
                                       AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr             ON cr.cr_order_number = cs.cs_order_number
                                       AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr                 ON wr.wr_order_number = cs.cs_order_number
                                       AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp                    ON wr.wr_web_page_sk = wp.wp_web_page_sk

-- Inventory information for the warehouse that supplied the catalog sale
LEFT JOIN inventory inv                  ON inv.inv_warehouse_sk = w_cat.w_warehouse_sk
                                       AND inv.inv_date_sk      = d.d_date_sk

-- Income band for the buyer household
LEFT JOIN income_band ib                 ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk

WHERE ss.ss_store_sk IN (SELECT ss_store_sk FROM qualifying_stores)
GROUP BY s.s_store_id, d.d_year
ORDER BY total_profit DESC
LIMIT 100
