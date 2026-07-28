WITH
    inv_agg AS (
        SELECT
            inv.inv_warehouse_sk,
            inv.inv_item_sk,
            SUM(inv.inv_quantity_on_hand) AS total_qty
        FROM inventory inv
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        WHERE d_inv.d_year = 2001
        GROUP BY inv.inv_warehouse_sk, inv.inv_item_sk
    ),
    sales_agg AS (
        SELECT
            d_sold.d_year,
            cc.cc_state,
            s.s_store_name,
            w.w_city,
            i.i_category,
            SUM(cs.cs_net_paid) AS total_sales,
            SUM(cr.cr_return_amount) AS total_returns,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
            SUM(COALESCE(inv_agg.total_qty, 0)) AS total_inventory_qty,
            AVG(p.p_cost) AS avg_promo_cost
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_time ON cs.cs_sold_time_sk = t_time.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
        LEFT JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
                           AND inv_agg.inv_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_returned_date_sk = d_sold.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
                                 AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
        WHERE d_sold.d_year = 2001
          AND t_time.t_sub_shift = 'morning'
          AND cc.cc_state = 'CA'
          AND i.i_current_price BETWEEN 100 AND 500
          AND w.w_city = 'Seattle'
          AND p.p_discount_active = 'Y'
        GROUP BY
            d_sold.d_year,
            cc.cc_state,
            s.s_store_name,
            w.w_city,
            i.i_category
    )
SELECT
    sa.d_year,
    sa.cc_state,
    sa.s_store_name,
    sa.w_city,
    sa.i_category,
    sa.total_sales,
    sa.total_returns,
    sa.total_profit,
    sa.distinct_orders,
    sa.total_inventory_qty,
    sa.avg_promo_cost,
    (SELECT AVG(ib2.ib_lower_bound) FROM income_band ib2) AS avg_income_lower,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_sales DESC) AS sales_rank
FROM sales_agg sa
ORDER BY sales_rank
LIMIT 100
