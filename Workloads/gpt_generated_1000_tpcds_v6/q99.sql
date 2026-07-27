WITH ws_agg AS (
    SELECT
        i.i_category,
        w.w_warehouse_name,
        d_sold.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year BETWEEN 1999 AND 2001
      AND w.w_warehouse_sq_ft > 200000
      AND i.i_current_price > 20
      AND hd_bill.hd_income_band_sk IS NOT NULL
      AND wp.wp_type = 'Content'
    GROUP BY i.i_category, w.w_warehouse_name, d_sold.d_year
),
inv_agg AS (
    SELECT
        i.i_category,
        w.w_warehouse_name,
        d_inv.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_inv.d_year BETWEEN 1999 AND 2001
      AND w.w_warehouse_sq_ft > 200000
      AND i.i_current_price > 20
    GROUP BY i.i_category, w.w_warehouse_name, d_inv.d_year
),
ret_agg AS (
    SELECT
        i.i_category,
        d_ret.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    WHERE d_ret.d_year BETWEEN 1999 AND 2001
      AND sr.sr_return_quantity > 0
      AND hd_ret.hd_vehicle_count >= 1
    GROUP BY i.i_category, d_ret.d_year
)
SELECT
    ws.i_category,
    ws.w_warehouse_name,
    ws.d_year,
    ws.total_sales,
    ws.total_profit,
    ws.sales_cnt,
    inv.total_qty_on_hand,
    ret.total_return_amt,
    ret.return_cnt,
    (ws.total_profit / NULLIF(ws.total_sales, 0)) AS profit_margin
FROM ws_agg ws
JOIN inv_agg inv
  ON ws.i_category = inv.i_category
 AND ws.w_warehouse_name = inv.w_warehouse_name
 AND ws.d_year = inv.d_year
JOIN ret_agg ret
  ON ws.i_category = ret.i_category
 AND ws.d_year = ret.d_year
WHERE EXISTS (
    SELECT 1
    FROM catalog_page cp
    JOIN date_dim d_cp ON cp.cp_end_date_sk = d_cp.d_date_sk
    WHERE cp.cp_type = 'Home'
      AND cp.cp_department = 'Books'
      AND d_cp.d_year = ws.d_year
)
  AND ws.total_sales > 10000
  AND ws.total_profit > 0
  AND inv.total_qty_on_hand > 5000
  AND ret.total_return_amt < 2000
ORDER BY ws.total_profit DESC
LIMIT 100
