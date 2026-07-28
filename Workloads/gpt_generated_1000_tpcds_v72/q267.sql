WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_category,
        i_current_price
    FROM tpcds.item
    WHERE i_category IN ('Sports', 'Electronics')
)
SELECT
    r.r_reason_desc AS reason,
    SUM(cr.cr_net_loss)               AS catalog_net_loss,
    SUM(sr.sr_net_loss)               AS store_net_loss,
    SUM(wr.wr_net_loss)               AS web_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders
FROM tpcds.catalog_returns cr
-- Item dimension used for catalog, store and web paths (first alias)
JOIN filtered_items i1 ON cr.cr_item_sk = i1.i_item_sk
-- Customer demographics – refunded and returning (different aliases)
JOIN tpcds.customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN tpcds.customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
-- Household demographics – refunded and returning (different aliases)
JOIN tpcds.household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN tpcds.household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
-- Customer address (refunded side)
JOIN tpcds.customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
-- Catalog page, ship mode, warehouse and reason for the catalog return
JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
-- Store side – sales and returns
JOIN tpcds.store_sales ss ON ss.ss_item_sk = i1.i_item_sk
JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
-- Web side – returns and page
JOIN tpcds.web_returns wr ON wr.wr_item_sk = i1.i_item_sk
JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
-- Income band via the refunded household demographic
JOIN tpcds.income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.warehouse w2
    WHERE w2.w_warehouse_sq_ft > 1000000
      AND w2.w_state = w.w_state
)
  AND i1.i_current_price > 10
GROUP BY r.r_reason_desc
ORDER BY catalog_net_loss DESC
LIMIT 100
