WITH joined AS (
    SELECT
        s.s_state,
        cp.cp_department,
        t.t_hour,
        ss.ss_ext_sales_price,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        cs.cs_order_number,
        ws.ws_order_number,
        cs.cs_item_sk,
        ws.ws_item_sk
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p1
      ON ss.ss_promo_sk = p1.p_promo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    -- catalog sales
    JOIN catalog_sales cs
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p2
      ON cs.cs_promo_sk = p2.p_promo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    -- catalog returns (optional, left join to keep rows without returns)
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    -- web sales (optional, left join)
    LEFT JOIN web_sales ws
      ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p3
      ON ws.ws_promo_sk = p3.p_promo_sk
    -- inventory (optional, left join)
    LEFT JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
aggregated AS (
    SELECT
        s_state,
        cp_department,
        t_hour,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT ws_order_number) AS distinct_web_orders
    FROM joined
    GROUP BY ROLLUP (s_state, cp_department, t_hour)
)
SELECT
    s_state,
    cp_department,
    t_hour,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    total_return_amount,
    total_inventory_qty,
    distinct_catalog_orders,
    distinct_web_orders,
    (total_store_sales + total_catalog_sales + total_web_sales - total_return_amount) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY (total_store_sales + total_catalog_sales + total_web_sales - total_return_amount) DESC) AS state_sales_rank
FROM aggregated
ORDER BY s_state, total_sales DESC
