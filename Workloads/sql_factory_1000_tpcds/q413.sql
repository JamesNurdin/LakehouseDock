SELECT
    cs.cs_item_sk,
    sm.sm_ship_mode_id,
    d.cd_gender AS shipping_gender,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    SUM(cs.cs_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_sales,
    CASE
        WHEN SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) > 0.2 THEN 'High Discount'
        ELSE 'Standard Discount'
    END AS discount_category,
    DENSE_RANK() OVER (ORDER BY SUM(cs.cs_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0) DESC) AS sales_rank
FROM catalog_sales cs
LEFT JOIN web_returns wr
    ON cs.cs_order_number = wr.wr_order_number
    AND cs.cs_item_sk = wr.wr_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics d
    ON cs.cs_ship_cdemo_sk = d.cd_demo_sk
GROUP BY cs.cs_item_sk, sm.sm_ship_mode_id, d.cd_gender
HAVING SUM(cs.cs_ext_sales_price) > 1000
ORDER BY sales_rank
LIMIT 20
