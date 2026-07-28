WITH raw_stats AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        cs.cs_ext_sales_price AS cs_sales,
        ws.ws_ext_sales_price AS ws_sales,
        sr.sr_return_amt AS return_amt,
        p.p_discount_active,
        sm.sm_type,
        w.w_warehouse_sq_ft,
        time_dim.t_hour
    FROM catalog_sales cs
    JOIN time_dim ON cs.cs_sold_time_sk = time_dim.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50
      AND w.w_warehouse_sq_ft > 600000
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND time_dim.t_hour BETWEEN 8 AND 18
      AND i.i_rec_start_date > DATE '2020-01-01'
)
SELECT
    i_item_id,
    i_product_name,
    SUM(cs_sales) AS total_catalog_sales,
    SUM(ws_sales) AS total_web_sales,
    SUM(return_amt) AS total_return_amount,
    (SUM(cs_sales) + SUM(ws_sales) - SUM(return_amt)) / NULLIF(SUM(cs_sales) + SUM(ws_sales), 0) AS profit_margin
FROM raw_stats
GROUP BY i_item_id, i_product_name
HAVING (SUM(cs_sales) + SUM(ws_sales)) > 1000
ORDER BY profit_margin DESC
LIMIT 100
