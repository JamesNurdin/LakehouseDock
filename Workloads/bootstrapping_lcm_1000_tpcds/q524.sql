SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    d_return.d_date AS return_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    d_store_closed.d_date AS store_closed_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_store_closed
    ON 1 = 1
JOIN store s
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_return.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    d_return.d_date,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_store_closed.d_date
ORDER BY total_return_amount DESC
LIMIT 100
