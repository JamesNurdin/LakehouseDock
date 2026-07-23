SELECT
    i.i_category,
    i.i_brand,
    d_sold.d_year AS sale_year,
    p.p_promo_name,
    SUM(s.cs_ext_sales_price) AS total_sales_amount,
    SUM(s.cs_quantity) AS total_quantity_sold,
    SUM(COALESCE(r_ret.cr_return_amount, 0)) AS total_return_amount,
    SUM(p.p_cost) AS total_promotion_cost,
    AVG(s.cs_ext_discount_amt) AS avg_discount_amount,
    SUM(s.cs_net_profit) AS total_net_profit
FROM catalog_sales s
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN item i_promo ON p.p_item_sk = i_promo.i_item_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN catalog_returns r_ret ON r_ret.cr_order_number = s.cs_order_number
LEFT JOIN date_dim d_returned ON r_ret.cr_returned_date_sk = d_returned.d_date_sk
WHERE d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND p.p_discount_active = 'Y'
GROUP BY
    i.i_category,
    i.i_brand,
    d_sold.d_year,
    p.p_promo_name
ORDER BY
    total_sales_amount DESC,
    i.i_category,
    d_sold.d_year
