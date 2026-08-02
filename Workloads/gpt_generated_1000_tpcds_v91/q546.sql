WITH inventory_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 700
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT 
    s.s_store_id,
    s.s_city,
    i.i_item_id,
    i.i_product_name,
    d_sales.d_year,
    p.p_promo_name,
    sm.sm_type,
    cp.cp_department,
    ib.ib_lower_bound,
    inventory_agg.total_on_hand,
    ss.ss_net_paid,
    cr.cr_return_amount,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank,
    CASE 
        WHEN ss.ss_net_paid > 1000 THEN 'High' 
        ELSE 'Low' 
    END AS sales_category
FROM (SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)) ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_cust ON ss.ss_cdemo_sk = cd_cust.cd_demo_sk
JOIN household_demographics hd_cust ON ss.ss_hdemo_sk = hd_cust.hd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_returns cr 
    ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returned_date_sk = d_sales.d_date_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg ON inventory_agg.inv_item_sk = i.i_item_sk
    AND inventory_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr 
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d_sales.d_date_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd_wr ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
JOIN income_band ib ON hd_cust.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_year = 2001
  AND i.i_category = 'Sports'
  AND sm.sm_type = 'OVERNIGHT'
  AND sm.sm_contract = 'A5BYO1qH8HGTTN'
  AND ib.ib_lower_bound >= 30000
  AND inventory_agg.total_on_hand > 1000
  AND s.s_state = 'CA'
  AND EXISTS (
        SELECT 1 
        FROM catalog_returns cr2 
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk 
          AND cr2.cr_return_amount > 0
    )
ORDER BY s.s_store_id, sales_rank
LIMIT 100
