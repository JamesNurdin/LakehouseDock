WITH combined AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS category,
        d.d_year AS year,
        sm.sm_type AS ship_mode_type,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        cs.cs_order_number AS order_num
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'UPS'
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND NOT EXISTS (
          SELECT 1 FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_date_sk = d.d_date_sk
      )
    UNION DISTINCT
    SELECT
        s.s_store_id AS store_id,
        i.i_category AS category,
        d.d_year AS year,
        sm.sm_type AS ship_mode_type,
        cs.cs_ext_sales_price AS sales,
        cs.cs_net_profit AS profit,
        cs.cs_ext_discount_amt AS discount,
        cs.cs_order_number AS order_num
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND sm.sm_carrier = 'DIAMOND'
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'NY'
      AND p.p_discount_active = 'N'
      AND NOT EXISTS (
          SELECT 1 FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_date_sk = d.d_date_sk
      )
)
SELECT
    store_id,
    category,
    year,
    ship_mode_type,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_num) AS order_cnt,
    AVG(discount) AS avg_discount
FROM combined
GROUP BY store_id, category, year, ship_mode_type
ORDER BY total_sales DESC
LIMIT 100
