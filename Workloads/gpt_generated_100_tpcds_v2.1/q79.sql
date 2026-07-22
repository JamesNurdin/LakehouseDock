WITH sales_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cc.cc_call_center_sk,
        cc.cc_class,
        cc.cc_country,
        wh.w_warehouse_sk,
        wh.w_state,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ss.ss_net_paid AS store_net_paid,
        cs.cs_net_paid AS catalog_net_paid,
        ws.ws_net_paid AS web_net_paid,
        cr.cr_return_amount AS return_amount,
        inv.inv_quantity_on_hand
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse wh ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND cc.cc_class = 'large'
      AND i.i_category = 'Electronics'
      AND EXISTS (
          SELECT 1 FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 0
      )
)
SELECT
    d_year,
    s_store_name,
    i_category,
    i_brand,
    SUM(store_net_paid) AS total_store_net_paid,
    SUM(catalog_net_paid) AS total_catalog_net_paid,
    SUM(web_net_paid) AS total_web_net_paid,
    SUM(return_amount) AS total_return_amount,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(store_net_paid + catalog_net_paid + web_net_paid - COALESCE(return_amount, 0)) AS net_revenue,
    CASE
        WHEN SUM(store_net_paid + catalog_net_paid + web_net_paid) > 100000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category = i_category) AS avg_price_in_category
FROM sales_agg
GROUP BY d_year, s_store_name, i_category, i_brand
HAVING SUM(store_net_paid + catalog_net_paid + web_net_paid) > 50000
ORDER BY net_revenue DESC
LIMIT 100
