/*
Goal: Identify high‑value orders from 2001 in the Sports department for California warehouses, combining sales, returns, and web sales data. The query aggregates per order, applies a CASE profit level, uses a correlated inventory subquery, unions sales and returns, intersects with web orders, excludes pure sales orders, and performs a full outer join to compare sales vs web metrics.
*/
WITH
sales_agg AS (
    SELECT
        cs.cs_order_number AS order_id,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        CASE WHEN cs.cs_quantity > 10 THEN 'large' ELSE 'small' END AS qty_category,
        (
            SELECT SUM(inv.inv_quantity_on_hand)
            FROM inventory inv
            WHERE inv.inv_warehouse_sk = cs.cs_warehouse_sk
              AND inv.inv_date_sk = cs.cs_sold_date_sk
        ) AS inventory_on_day,
        d.d_year,
        w.w_state,
        cp.cp_department,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Sports'
      AND w.w_state = 'CA'
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > 0
),
returns_agg AS (
    SELECT
        cr.cr_order_number AS order_id,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity,
        d.d_year,
        w.w_state,
        cp.cp_department,
        hd.hd_income_band_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Sports'
      AND w.w_state = 'CA'
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
),
web_agg AS (
    SELECT
        ws.ws_order_number AS order_id,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        d.d_year,
        w.w_state,
        ws.ws_web_site_sk,
        hd.hd_income_band_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND site.web_state = 'CA'
      AND w.w_state = 'CA'
      AND ws.ws_quantity > 5
      AND ws.ws_net_profit > 0
),
union_sales_returns AS (
    SELECT
        order_id,
        net_profit,
        quantity,
        qty_category,
        inventory_on_day,
        d_year,
        w_state,
        cp_department,
        hd_income_band_sk
    FROM sales_agg
    UNION DISTINCT
    SELECT
        order_id,
        return_amount AS net_profit,
        return_quantity AS quantity,
        NULL AS qty_category,
        NULL AS inventory_on_day,
        d_year,
        w_state,
        cp_department,
        hd_income_band_sk
    FROM returns_agg
),
intersect_orders AS (
    SELECT order_id FROM sales_agg
    INTERSECT
    SELECT order_id FROM web_agg
),
except_orders AS (
    SELECT order_id FROM sales_agg
    EXCEPT
    SELECT order_id FROM returns_agg
),
full_join_sales_web AS (
    SELECT
        COALESCE(s.order_id, w.order_id) AS order_id,
        s.net_profit AS sales_net_profit,
        w.net_profit AS web_net_profit,
        s.quantity AS sales_quantity,
        w.quantity AS web_quantity,
        s.qty_category,
        s.inventory_on_day
    FROM sales_agg s
    FULL OUTER JOIN web_agg w ON s.order_id = w.order_id
),
final_agg AS (
    SELECT
        f.order_id,
        f.sales_net_profit,
        f.web_net_profit,
        f.sales_quantity,
        f.web_quantity,
        f.qty_category,
        f.inventory_on_day,
        CASE WHEN f.sales_net_profit > 1000 THEN 'high' ELSE 'low' END AS profit_level
    FROM full_join_sales_web f
    WHERE f.order_id IN (SELECT order_id FROM intersect_orders)
      AND f.order_id NOT IN (SELECT order_id FROM except_orders)
)
SELECT
    order_id,
    sales_net_profit,
    web_net_profit,
    sales_quantity,
    web_quantity,
    qty_category,
    inventory_on_day,
    profit_level
FROM final_agg
ORDER BY order_id
LIMIT 100
