WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        ws.ws_quantity,
        w.w_warehouse_id,
        w.w_country,
        w.w_gmt_offset,
        cp.cp_department,
        dr_ret.d_year,
        dr_ret.d_month_seq,
        ds.d_quarter_seq,
        ws.ws_sales_price
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim dr_ret ON cr.cr_returned_date_sk = dr_ret.d_date_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    WHERE dr_ret.d_year = 2001
      AND dr_ret.d_month_seq BETWEEN 1 AND 12
      AND w.w_country = 'United States'
      AND w.w_gmt_offset = -5.00
      AND cr.cr_ship_mode_sk IN (4, 5, 6)
      AND cp.cp_department = 'Electronics'
      AND ds.d_quarter_seq = 4
      AND ws.ws_sales_price > 100
      AND ws.ws_quantity >= 2
),

distinct_pairs AS (
    SELECT DISTINCT w_warehouse_id, cp_department
    FROM filtered
),

agg AS (
    SELECT
        f.w_warehouse_id,
        f.cp_department,
        SUM(f.cr_return_amount) AS total_return_amount,
        SUM(f.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT f.cr_order_number) AS distinct_return_orders,
        COUNT(DISTINCT f.ws_order_number) AS distinct_sales_orders
    FROM filtered f
    GROUP BY f.w_warehouse_id, f.cp_department
)

SELECT
    a.w_warehouse_id,
    a.cp_department,
    a.total_return_amount,
    a.total_sales_amount,
    a.total_sales_amount - a.total_return_amount AS net_amount,
    a.distinct_return_orders,
    a.distinct_sales_orders
FROM agg a
JOIN distinct_pairs dp
  ON a.w_warehouse_id = dp.w_warehouse_id
 AND a.cp_department = dp.cp_department
WHERE a.total_sales_amount > 1000
ORDER BY net_amount DESC
LIMIT 100
