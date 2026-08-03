WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_brand = 'Brand1'
    )
)
SELECT
    cc.cc_name,
    i.i_brand,
    d_sold.d_year,
    sm.sm_type,
    wsit.web_name,
    SUM(cs.cs_net_paid)               AS total_catalog_net_paid,
    SUM(ws.ws_net_paid)               AS total_web_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(inv.inv_quantity_on_hand)    AS avg_inventory_qty,
    MIN(ib.ib_lower_bound)           AS min_income_lower,
    MAX(ib.ib_upper_bound)           AS max_income_upper,
    SUM(metric_val)                  AS sum_metric_values
FROM filtered_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN date_dim d_store_closed
  ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim d_web_open
  ON wsit.web_open_date_sk = d_web_open.d_date_sk
JOIN date_dim d_web_close
  ON wsit.web_close_date_sk = d_web_close.d_date_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr_returned
  ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
CROSS JOIN UNNEST(ARRAY[ws.ws_quantity, ws.ws_sales_price]) AS t(metric_val)
WHERE
    d_sold.d_year = 2001
    AND d_sold.d_month_seq = 12
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND wsit.web_country = 'USA'
    AND r.r_reason_desc LIKE '%service%'
GROUP BY
    cc.cc_name,
    i.i_brand,
    d_sold.d_year,
    sm.sm_type,
    wsit.web_name
LIMIT 100
