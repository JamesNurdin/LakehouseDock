SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_quarter_name AS sales_quarter,
    s.s_state,
    s.s_city,
    CASE 
        WHEN i_sold.i_category = 'Electronics' THEN 'Electronics'
        WHEN i_sold.i_category = 'Furniture' THEN 'Furniture'
        ELSE 'Other'
    END AS category_group,
    i_sold.i_brand,
    p.p_promo_name,
    i_promo.i_brand AS promo_item_brand,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    CASE 
        WHEN SUM(ss.ss_ext_sales_price) > 500000 THEN 'Very High'
        WHEN SUM(ss.ss_ext_sales_price) > 200000 THEN 'High'
        WHEN SUM(ss.ss_ext_sales_price) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_volume_category,
    CASE 
        WHEN MAX(CASE WHEN s.s_closed_date_sk IS NOT NULL AND d_sold.d_date_sk > s.s_closed_date_sk THEN 1 ELSE 0 END) = 1 THEN 'Closed' ELSE 'Open' 
    END AS store_status_at_sale,
    CASE 
        WHEN MAX(CASE WHEN d_sold.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk THEN 1 ELSE 0 END) = 1 THEN 'Active' ELSE 'Inactive' 
    END AS promotion_status_at_sale,
    ROUND(
        CASE 
            WHEN SUM(ss.ss_ext_list_price) > 0 THEN (SUM(ss.ss_ext_discount_amt) / SUM(ss.ss_ext_list_price)) * 100
            ELSE 0
        END, 2) AS discount_percent,
    date_diff('day', MIN(d_promo_start.d_date), MIN(d_promo_end.d_date)) AS promotion_duration_days,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MIN(d_promo_end.d_date) AS promo_end_date,
    MIN(d_closed.d_date) AS store_closure_date
FROM store_sales ss
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i_sold ON ss.ss_item_sk = i_sold.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN item i_promo ON p.p_item_sk = i_promo.i_item_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2022
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND i_sold.i_category IS NOT NULL
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_state,
    s.s_city,
    CASE 
        WHEN i_sold.i_category = 'Electronics' THEN 'Electronics'
        WHEN i_sold.i_category = 'Furniture' THEN 'Furniture'
        ELSE 'Other'
    END,
    i_sold.i_brand,
    p.p_promo_name,
    i_promo.i_brand
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
