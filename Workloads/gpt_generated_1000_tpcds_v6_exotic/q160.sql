WITH cs_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_department,
        i.i_brand,
        i.i_category,
        d.d_year,
        d.d_date,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        w.w_warehouse_name,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim tcs
        ON cs.cs_sold_time_sk = tcs.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 100
      AND cp.cp_department = 'Sports'
      AND sm.sm_type = 'AIR'
      AND d.d_date = DATE '2001-01-15'
)
SELECT
    d.d_year,
    i.i_brand,
    cs_agg.cp_department,
    COUNT(DISTINCT cs_agg.cs_order_number) AS num_orders,
    SUM(cs_agg.cs_ext_sales_price) AS total_sales,
    AVG(cs_agg.cs_net_profit) AS avg_profit,
    MIN(cs_agg.cs_quantity) AS min_qty,
    MAX(cs_agg.cs_quantity) AS max_qty,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_ext_sales_price) AS web_total_sales,
    (SELECT AVG(cs_ext_sales_price) FROM catalog_sales) AS overall_avg_sales
FROM cs_agg
JOIN store_sales ss
    ON ss.ss_sold_date_sk = cs_agg.cs_sold_date_sk
   AND ss.ss_item_sk = cs_agg.cs_item_sk
JOIN date_dim d
    ON d.d_date_sk = ss.ss_sold_date_sk
JOIN time_dim t
    ON t.t_time_sk = ss.ss_sold_time_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = ss.ss_hdemo_sk
JOIN item i
    ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs_agg.cs_order_number
          AND cr.cr_item_sk = cs_agg.cs_item_sk
      )
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk = ws.ws_item_sk
      )
  AND ws.ws_coupon_amt > 100
  AND wp.wp_max_ad_count IS NOT NULL
  AND t.t_hour = 14
GROUP BY
    d.d_year,
    i.i_brand,
    cs_agg.cp_department
ORDER BY total_sales DESC
LIMIT 100
