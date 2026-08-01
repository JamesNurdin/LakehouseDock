WITH inv_daily AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_inventory_on_date
    FROM inventory
    WHERE inv_quantity_on_hand > 20
    GROUP BY inv_date_sk
)
SELECT
    dd.d_year,
    s.s_state,
    hd.hd_vehicle_count,
    cc.cc_market_manager,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(i.total_inventory_on_date) AS total_inventory,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
FROM store_sales ss
INNER JOIN date_dim dd
    ON ss.ss_sold_date_sk = dd.d_date_sk
INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN call_center cc
    ON dd.d_date_sk = cc.cc_open_date_sk
INNER JOIN inv_daily i
    ON dd.d_date_sk = i.inv_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = dd.d_date_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
   AND sr.sr_store_sk = s.s_store_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_date_sk = dd.d_date_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_date_sk = dd.d_date_sk
WHERE dd.d_year = 1999
  AND s.s_state = 'CA'
  AND cc.cc_mkt_class = 'Written'
  AND ss.ss_quantity > 1
  AND wp.wp_type = 'Home'
  AND i.total_inventory_on_date > 100
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = ss.ss_item_sk
          AND cr2.cr_return_amount > 0
    )
GROUP BY dd.d_year, s.s_state, hd.hd_vehicle_count, cc.cc_market_manager
ORDER BY total_sales DESC
LIMIT 100
