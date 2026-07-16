SELECT
    ds_sold.d_year,
    ds_ship.d_month_seq,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    s.s_store_name,
    i2.i_color AS promo_item_color,
    CASE
        WHEN cs.cs_quantity <= 5 THEN '0-5'
        WHEN cs.cs_quantity <= 10 THEN '6-10'
        ELSE '11+'
    END AS quantity_bucket,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(CASE WHEN cs.cs_quantity > 10 THEN cs.cs_net_paid ELSE 0 END) AS high_qty_net_paid,
    DATE_DIFF('day', ds_promo_start.d_date, ds_promo_end.d_date) AS promo_duration_days
FROM catalog_sales cs
JOIN date_dim ds_sold
    ON cs.cs_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_ship
    ON cs.cs_ship_date_sk = ds_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim ds_promo_start
    ON p.p_start_date_sk = ds_promo_start.d_date_sk
JOIN date_dim ds_promo_end
    ON p.p_end_date_sk = ds_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ds_sold.d_date_sk
JOIN item i2
    ON p.p_item_sk = i2.i_item_sk
WHERE ds_sold.d_year = 2022
  AND i.i_category = 'Books'
GROUP BY
    ds_sold.d_year,
    ds_ship.d_month_seq,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    s.s_store_name,
    i2.i_color,
    CASE
        WHEN cs.cs_quantity <= 5 THEN '0-5'
        WHEN cs.cs_quantity <= 10 THEN '6-10'
        ELSE '11+'
    END,
    ds_promo_start.d_date,
    ds_promo_end.d_date
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
