SELECT
    i.i_brand,
    i.i_category,
    dSale.d_year,
    dSale.d_quarter_name,
    s.s_state,
    COUNT(DISTINCT s.s_store_id) AS num_stores,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    (SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0)) * 100 AS profit_margin_percent,
    SUM(ss.ss_ext_discount_amt) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS discount_rate,
    SUM(p.p_cost) FILTER (WHERE p.p_discount_active = 'Y') AS total_active_promo_cost,
    AVG(p.p_cost) FILTER (WHERE p.p_discount_active = 'Y') AS avg_active_promo_cost,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    AVG(ss.ss_ext_tax) AS avg_tax,
    COUNT(DISTINCT p.p_promo_id) AS num_promos
FROM store_sales ss
JOIN date_dim dSale
    ON ss.ss_sold_date_sk = dSale.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim dPromoStart
    ON p.p_start_date_sk = dPromoStart.d_date_sk
JOIN date_dim dPromoEnd
    ON p.p_end_date_sk = dPromoEnd.d_date_sk
LEFT JOIN date_dim dClosed
    ON s.s_closed_date_sk = dClosed.d_date_sk
WHERE dSale.d_year = 2022
  AND dClosed.d_date IS NULL
  AND dSale.d_date BETWEEN dPromoStart.d_date AND dPromoEnd.d_date
GROUP BY
    i.i_brand,
    i.i_category,
    dSale.d_year,
    dSale.d_quarter_name,
    s.s_state
HAVING SUM(ss.ss_quantity) > 500
ORDER BY total_sales DESC
LIMIT 100
