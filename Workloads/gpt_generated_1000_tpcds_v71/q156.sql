/*
  Goal: Summarize return amounts from store, catalog and web channels together with current inventory levels, 
  grouped by store, call center, catalog page and web page using a ROLLUP grouping set. The query filters on high‑priced items, 
  California call centers and air shipping mode, then ranks stores by their total store return amount.
*/
WITH aggregated AS (
    SELECT
        s.s_store_name               AS store_name,
        cc.cc_name                   AS call_center_name,
        cp.cp_catalog_number         AS catalog_number,
        wp.wp_url                    AS web_url,
        i.i_item_id                  AS item_id,
        SUM(COALESCE(sr.sr_return_amt, 0))      AS store_return_amt,
        SUM(COALESCE(cr.cr_return_amount, 0))   AS catalog_return_amt,
        SUM(COALESCE(wr.wr_return_amt, 0))      AS web_return_amt,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS inventory_qty
    FROM tpcds.date_dim d
    /* store return side */
    LEFT JOIN tpcds.store_returns sr          ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.item i                    ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN tpcds.store s                   ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN tpcds.customer c               ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN tpcds.customer_address ca      ON ca.ca_address_sk = sr.sr_addr_sk
    LEFT JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
    /* catalog return side */
    LEFT JOIN tpcds.catalog_returns cr       ON cr.cr_returned_date_sk = d.d_date_sk
                                             AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.call_center cc            ON cc.cc_call_center_sk = cr.cr_call_center_sk
    LEFT JOIN tpcds.catalog_page cp           ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN tpcds.ship_mode sm              ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN tpcds.warehouse w               ON w.w_warehouse_sk = cr.cr_warehouse_sk
    /* web return side */
    LEFT JOIN tpcds.web_returns wr           ON wr.wr_returned_date_sk = d.d_date_sk
                                             AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_page wp               ON wp.wp_web_page_sk = wr.wr_web_page_sk
    /* inventory */
    LEFT JOIN tpcds.inventory inv             ON inv.inv_date_sk = d.d_date_sk
                                             AND inv.inv_item_sk = i.i_item_sk
                                             AND inv.inv_warehouse_sk = w.w_warehouse_sk
    /* household income band */
    LEFT JOIN tpcds.income_band ib            ON ib.ib_income_band_sk = hd.hd_income_band_sk
    /* additional joins to satisfy join‑rules */
    LEFT JOIN tpcds.store s_closed            ON s_closed.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc_closed     ON cc_closed.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_page cp_start     ON cp_start.cp_start_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_page wp_creation      ON wp_creation.wp_creation_date_sk = d.d_date_sk
    WHERE i.i_current_price > 50
      AND cc.cc_state = 'CA'
      AND sm.sm_code = 'AIR'
    GROUP BY ROLLUP(s.s_store_name, cc.cc_name, cp.cp_catalog_number, wp.wp_url, i.i_item_id)
)
SELECT
    store_name,
    call_center_name,
    catalog_number,
    web_url,
    item_id,
    store_return_amt,
    catalog_return_amt,
    web_return_amt,
    inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY store_return_amt DESC) AS store_return_rank
FROM aggregated
ORDER BY store_return_rank, store_name
LIMIT 100
