WITH store_info AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_closed_date_sk,
        dd.d_year AS store_closed_year,
        dd.d_date AS store_closed_date
    FROM store s
    JOIN date_dim dd
        ON s.s_closed_date_sk = dd.d_date_sk
)

SELECT
    si.s_store_id,
    si.s_store_name,
    p.p_promo_name,
    dd_sold.d_year AS sale_year,
    dd_sold.d_month_seq AS sale_month,
    dd_ship.d_year AS ship_year,
    dd_ship.d_month_seq AS ship_month,
    dd_return.d_year AS return_year,
    dd_return.d_month_seq AS return_month,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_after_returns,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    CASE WHEN SUM(cs.cs_quantity) > 0 THEN
         SUM(cr.cr_return_quantity) / NULLIF(SUM(cs.cs_quantity), 0)
    END AS return_rate,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    p.p_cost AS promotion_cost,
    dd_promo_start.d_date AS promo_start_date,
    dd_promo_end.d_date AS promo_end_date,
    si.store_closed_year,
    si.store_closed_date,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_ship_cost) AS total_shipping_cost,
    SUM(cs.cs_ext_tax) AS total_tax
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim dd_promo_start
    ON p.p_start_date_sk = dd_promo_start.d_date_sk
JOIN date_dim dd_promo_end
    ON p.p_end_date_sk = dd_promo_end.d_date_sk
JOIN date_dim dd_return
    ON cr.cr_returned_date_sk = dd_return.d_date_sk
JOIN store_info si
    ON 1 = 1
WHERE dd_sold.d_year >= 2000
  AND p.p_discount_active = 'Y'
GROUP BY
    si.s_store_id,
    si.s_store_name,
    p.p_promo_name,
    dd_sold.d_year,
    dd_sold.d_month_seq,
    dd_ship.d_year,
    dd_ship.d_month_seq,
    dd_return.d_year,
    dd_return.d_month_seq,
    p.p_cost,
    dd_promo_start.d_date,
    dd_promo_end.d_date,
    si.store_closed_year,
    si.store_closed_date
ORDER BY total_sales_inc_tax DESC
LIMIT 100
