SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    t.t_hour,
    t.t_minute,
    ss.ss_quantity,
    ss.ss_sales_price,
    ss.ss_ext_sales_price,
    ss.ss_ext_sales_price * 0.9 AS discounted_price,
    CASE 
        WHEN ss.ss_quantity > 28 THEN 'Bulk'
        WHEN ss.ss_quantity > 14 THEN 'Medium'
        ELSE 'Small'
    END AS quantity_category,
    CASE
        WHEN ss.ss_ext_sales_price > 2375.12 THEN 'High'
        WHEN ss.ss_ext_sales_price > 440.22 THEN 'Medium'
        ELSE 'Low'
    END AS sales_price_category,
    ss.ss_ext_sales_price - ss.ss_ext_discount_amt AS net_before_tax,
    ss.ss_ext_sales_price - ss.ss_ext_discount_amt + ss.ss_ext_tax AS net_with_tax,
    CONCAT('Time ', CAST(t.t_hour AS VARCHAR), ':', LPAD(CAST(t.t_minute AS VARCHAR), 2, '0')) AS time_label
FROM store_sales ss
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
WHERE ss.ss_sold_date_sk = 2451831
