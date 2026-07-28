/* goal: Analyse combined profitability and loss across store sales, catalog sales, and web returns per promotion and item brand for the year 2001, showing subtotals and a rank per promotion year */
WITH
    -- aliases for the date dimension used in different roles
    d_sales AS (SELECT * FROM date_dim),
    d_sr    AS (SELECT * FROM date_dim),
    d_cs_sold AS (SELECT * FROM date_dim),
    d_cs_ship AS (SELECT * FROM date_dim),
    d_cr    AS (SELECT * FROM date_dim),
    d_wr    AS (SELECT * FROM date_dim),
    d_inv   AS (SELECT * FROM date_dim),
    d_wp_create AS (SELECT * FROM date_dim),
    d_wp_access AS (SELECT * FROM date_dim)
SELECT
    p.p_promo_name,
    i.i_brand,
    d_sales.d_year,
    SUM(ss.ss_net_profit)                AS store_sales_profit,
    SUM(cs.cs_net_paid)                  AS catalog_sales_net_paid,
    SUM(cr.cr_net_loss)                  AS catalog_return_loss,
    SUM(sr.sr_net_loss)                  AS store_return_loss,
    SUM(wr.wr_net_loss)                  AS web_return_loss,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY d_sales.d_year) AS promo_year_rank
FROM store_sales ss
JOIN d_sales          ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i           ON ss.ss_item_sk = i.i_item_sk
JOIN customer_address ca_ss         ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN promotion p       ON ss.ss_promo_sk = p.p_promo_sk
-- reuse ITEM as a second alias for inventory role
JOIN item i_inv        ON i_inv.i_item_sk = i.i_item_sk
JOIN inventory inv     ON inv.inv_item_sk = i_inv.i_item_sk
JOIN warehouse w_inv  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN d_inv             ON inv.inv_date_sk = d_inv.d_date_sk
-- store returns linked to the same sale
JOIN store_returns sr  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN d_sr              ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN reason r_sr       ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca_sr        ON sr.sr_addr_sk = ca_sr.ca_address_sk
-- catalog sales linked via the same ITEM
JOIN catalog_sales cs  ON cs.cs_item_sk = i.i_item_sk
JOIN d_cs_sold         ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN d_cs_ship         ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN customer_address ca_cs_bill   ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
JOIN customer_address ca_cs_ship   ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk
JOIN warehouse w_cs    ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN promotion p_cs    ON cs.cs_promo_sk = p_cs.p_promo_sk
-- catalog returns tied to the catalog sale
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN d_cr               ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN reason r_cr        ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer_address ca_cr_refund   ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
JOIN customer_address ca_cr_return   ON cr.cr_returning_addr_sk = ca_cr_return.ca_address_sk
JOIN warehouse w_cr     ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
-- web returns linked to the same ITEM
JOIN web_returns wr    ON wr.wr_item_sk = i.i_item_sk
JOIN d_wr               ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r_wr        ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer_address ca_wr_refund   ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_return   ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
JOIN web_page wp        ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN d_wp_create        ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN d_wp_access        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sales.d_year = 2001
GROUP BY ROLLUP (p.p_promo_name, i.i_brand, d_sales.d_year)
ORDER BY p.p_promo_name, i.i_brand, d_sales.d_year
LIMIT 100
