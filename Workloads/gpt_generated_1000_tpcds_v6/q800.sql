WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_brand
),
promo_stats AS (
    SELECT
        p.p_promo_sk,
        AVG(p.p_cost) AS avg_promo_cost
    FROM promotion p
    GROUP BY p.p_promo_sk
)
SELECT DISTINCT
    i.i_product_name,
    i.i_category,
    cc.cc_name AS call_center_name,
    w.w_warehouse_name,
    sm.sm_type AS ship_mode_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_ext_discount_amt,
    COALESCE(wr.wr_return_amt, 0) AS return_amount,
    wp.wp_url,
    SUM(cs.cs_net_paid) OVER (PARTITION BY i.i_brand ORDER BY cs.cs_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_by_brand,
    ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS sales_rank,
    (SELECT AVG(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS avg_active_promo_cost,
    (SELECT COUNT(*) FROM web_returns WHERE wr_item_sk = i.i_item_sk AND wr_return_amt > 100) AS high_value_returns
FROM catalog_sales cs
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN item_sales isales ON isales.i_item_sk = i.i_item_sk
JOIN promo_stats pstats ON pstats.p_promo_sk = p.p_promo_sk
WHERE i.i_category = 'Electronics'
  AND cs.cs_net_paid > 100
ORDER BY cs.cs_net_paid DESC
LIMIT 100
