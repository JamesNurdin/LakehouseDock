WITH distinct_warehouses AS (
    SELECT DISTINCT w_warehouse_sk, w_warehouse_name, w_county
    FROM warehouse
),
sampled_sales AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_sold_date_sk,
        cs_ship_date_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_cdemo_sk,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        cs_net_paid,
        cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    cr.cr_order_number,
    ds.d_year AS sold_year,
    ds.d_month_seq AS sold_month,
    dw.w_warehouse_name,
    sm.sm_type AS ship_mode_type,
    cd.cd_gender AS customer_gender,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_net_loss,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = dw.w_warehouse_sk
    ) AS avg_return_amount_warehouse,
    ROW_NUMBER() OVER (PARTITION BY dw.w_warehouse_name ORDER BY cr.cr_return_amount DESC) AS rn_return_amount,
    DENSE_RANK() OVER (PARTITION BY ds.d_year ORDER BY cr.cr_return_amount DESC) AS rank_year_return,
    CASE
        WHEN cr.cr_return_amount > 1000 THEN 'High'
        WHEN cr.cr_return_amount > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category
FROM sampled_sales cs
JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN distinct_warehouses dw ON cs.cs_warehouse_sk = dw.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
    AND cr.cr_warehouse_sk = dw.w_warehouse_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
WHERE 
    ds.d_fy_year = 1912
    AND dw.w_county = 'Walker County'
    AND cd.cd_gender = 'M'
    AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE wr.wr_reason_sk = r.r_reason_sk
          AND wp.wp_type = 'HomePage'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = r.r_reason_sk
          AND wr2.wr_returned_date_sk = dr.d_date_sk
    )
ORDER BY rank_year_return, cr.cr_return_amount DESC
LIMIT 100
