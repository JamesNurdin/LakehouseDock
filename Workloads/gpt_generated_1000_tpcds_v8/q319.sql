WITH sales_orders AS (
        SELECT DISTINCT cs.cs_order_number AS order_number
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 0
    ),
    return_orders AS (
        SELECT DISTINCT cr.cr_order_number AS order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
    ),
    common_orders AS (
        SELECT order_number FROM sales_orders
        INTERSECT
        SELECT order_number FROM return_orders
    ),
    aggregated AS (
        SELECT
            d.d_year,
            i.i_brand,
            i.i_category,
            sm.sm_type,
            cs.cs_item_sk,
            cs.cs_order_number,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_profit,
            SUM(cs.cs_quantity) AS total_quantity,
            SUM(cs.cs_sales_price) AS total_sales_price
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        LEFT JOIN web_sales ws ON cs.cs_sold_date_sk = ws.ws_sold_date_sk AND cs.cs_item_sk = ws.ws_item_sk
        LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        LEFT JOIN inventory inv ON cs.cs_sold_date_sk = inv.inv_date_sk AND cs.cs_item_sk = inv.inv_item_sk
        WHERE d.d_year = 2001
          AND i.i_brand_id = 10008011
          AND ib.ib_lower_bound >= 50000
          AND sm.sm_type = 'AIR'
          AND d.d_day_name = 'Saturday'
          AND cs.cs_order_number IN (SELECT order_number FROM common_orders)
        GROUP BY ROLLUP (d.d_year, i.i_brand, i.i_category, sm.sm_type, cs.cs_item_sk, cs.cs_order_number)
        HAVING SUM(cs.cs_net_profit) > 0
    )
SELECT
    a.d_year,
    a.i_brand,
    a.i_category,
    a.sm_type,
    a.order_cnt,
    a.total_net_paid,
    a.total_profit,
    a.total_quantity,
    a.total_sales_price,
    -- correlated scalar subquery: total return amount for the item of this row
    (SELECT COALESCE(SUM(cr2.cr_return_amount), 0)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = a.cs_item_sk) AS item_total_return_amount,
    t.metric_value,
    CASE t.metric_idx
        WHEN 1 THEN 'total_quantity'
        WHEN 2 THEN 'total_sales_price'
        ELSE 'unknown_metric'
    END AS metric_name
FROM aggregated a
CROSS JOIN UNNEST(ARRAY[a.total_quantity, a.total_sales_price]) WITH ORDINALITY AS t(metric_value, metric_idx)
ORDER BY a.total_profit DESC
LIMIT 100
