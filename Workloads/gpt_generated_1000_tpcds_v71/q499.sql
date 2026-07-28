WITH base AS (
    SELECT
        d_sold.d_year AS year,
        i.i_category AS category,
        r.r_reason_desc AS reason_desc,
        cs.cs_net_profit AS catalog_profit,
        ws.ws_net_profit AS web_profit,
        cs.cs_order_number AS catalog_order,
        ws.ws_order_number AS web_order,
        hd_bill.hd_vehicle_count AS vehicle_count,
        t_sold.t_sub_shift AS sub_shift
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN web_sales ws ON cs.cs_item_sk = ws.ws_item_sk
        AND cs.cs_sold_date_sk = ws.ws_sold_date_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    JOIN date_dim d_ws_return ON wr.wr_returned_date_sk = d_ws_return.d_date_sk
    JOIN time_dim t_ws_return ON wr.wr_returned_time_sk = t_ws_return.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_sub_shift = 'morning'
      AND hd_bill.hd_vehicle_count = 1
      AND r.r_reason_sk IN (6, 7)
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_amount > 100
      )
),
agg AS (
    SELECT
        year,
        category,
        reason_desc,
        SUM(catalog_profit) AS total_catalog_profit,
        SUM(web_profit) AS total_web_profit,
        SUM(catalog_profit) + SUM(web_profit) AS total_profit,
        COUNT(DISTINCT catalog_order) AS catalog_orders,
        COUNT(DISTINCT web_order) AS web_orders
    FROM base
    GROUP BY year, category, reason_desc
    HAVING SUM(catalog_profit) + SUM(web_profit) > 10000
)
SELECT
    year,
    category,
    reason_desc,
    total_catalog_profit,
    total_web_profit,
    total_profit,
    catalog_orders,
    web_orders,
    RANK() OVER (PARTITION BY year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
