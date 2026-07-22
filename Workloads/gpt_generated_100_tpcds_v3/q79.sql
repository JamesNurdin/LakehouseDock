/* goal: Analyze 2001 store performance in the United States, aggregating net profit, return losses and inventory across stores, ship modes and months, limited to customers who have at least one web return. */
SELECT
    s.s_store_name,
    sm.sm_type,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(inv1.inv_quantity_on_hand) AS total_inventory_qty,
    SUM(inv2.inv_quantity_on_hand) AS total_inventory_qty_alt
FROM
    store_sales ss
    INNER JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d_sales.d_date_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_store_sk = s.s_store_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sales.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returning_addr_sk = ca.ca_address_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN inventory inv1
        ON inv1.inv_date_sk = d_sales.d_date_sk
        AND inv1.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv2
        ON inv2.inv_date_sk = d_closed.d_date_sk
        AND inv2.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE
    EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returned_date_sk = d_sales.d_date_sk
          AND wr.wr_refunded_customer_sk = c.c_customer_sk
    )
    AND d_sales.d_year = 2001
    AND s.s_country = 'United States'
GROUP BY
    s.s_store_name,
    sm.sm_type,
    d_sales.d_year,
    d_sales.d_month_seq
ORDER BY
    total_net_profit DESC
LIMIT 100
