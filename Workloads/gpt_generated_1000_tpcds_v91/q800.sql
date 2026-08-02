WITH base_agg AS (
    SELECT
        cc.cc_name AS cc_name,
        d_sold.d_year AS sales_year,
        w.w_warehouse_id AS warehouse_id,
        w.w_warehouse_sk AS warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
            SELECT 1
            FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
              AND wr2.wr_item_sk = i.i_item_sk
        )
      AND d_sold.d_year = 2000
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND hd_bill.hd_income_band_sk = 3
    GROUP BY cc.cc_name,
             d_sold.d_year,
             w.w_warehouse_id,
             w.w_warehouse_sk
)
SELECT
    ba.cc_name,
    ba.sales_year,
    ba.warehouse_id,
    SUM(ba.total_sales) AS sum_total_sales,
    SUM(ba.total_return_amount) AS sum_total_returns,
    AVG(ba.total_inventory_on_hand) AS avg_inventory_on_hand,
    (SELECT SUM(inv2.inv_quantity_on_hand)
       FROM inventory inv2
       WHERE inv2.inv_warehouse_sk = ba.warehouse_sk) AS total_inventory_warehouse,
    SUM(ba.total_sales) / NULLIF(SUM(ba.total_inventory_on_hand), 0) AS sales_per_inventory
FROM base_agg ba
GROUP BY ba.cc_name,
         ba.sales_year,
         ba.warehouse_id,
         ba.warehouse_sk
HAVING SUM(ba.total_sales) > 100000
ORDER BY sum_total_sales DESC
LIMIT 100
