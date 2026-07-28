WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        c.c_customer_id,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        d.d_date,
        d.d_year,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_id,
        w.w_state,
        cp.cp_department,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        site.web_name
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 10 AND 100
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp_sub
          WHERE cp_sub.cp_department = 'Books'
            AND cp_sub.cp_start_date_sk = d.d_date_sk
      )
)
SELECT
    sd.ws_order_number,
    sd.c_customer_id,
    sd.i_item_id,
    sd.i_product_name,
    sd.d_date,
    sd.ws_quantity,
    sd.ws_ext_sales_price,
    CASE
        WHEN sd.ib_upper_bound <= 40000 THEN 'Low Income'
        WHEN sd.ib_lower_bound >= 100000 THEN 'High Income'
        ELSE 'Mid Income'
    END AS income_category,
    ROW_NUMBER() OVER (PARTITION BY sd.c_customer_id ORDER BY sd.ws_ext_sales_price DESC) AS sales_rank,
    SUM(sd.ws_ext_sales_price) OVER (PARTITION BY sd.c_customer_id) AS total_customer_sales
FROM sales_data sd
ORDER BY sd.ws_ext_sales_price DESC
LIMIT 100
