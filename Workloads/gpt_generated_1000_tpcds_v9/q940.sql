WITH sales_data AS (
    SELECT
        d_sold.d_date AS sales_date,
        i.i_item_sk,
        i.i_product_name,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        RANK() OVER (PARTITION BY i.i_item_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        p.p_promo_name,
        sm.sm_type,
        cr.cr_return_amount,
        sr.sr_return_amt,
        d_sr.d_date AS store_return_date
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE d_sold.d_year = 2002
      AND i.i_brand_id IN (350, 167)
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
      AND cs.cs_net_paid > 1000
      AND sm.sm_type = 'AIR'
)
SELECT
    sales_date,
    i_item_sk,
    i_product_name,
    cs_order_number,
    cs_quantity,
    cs_ext_sales_price,
    cs_net_paid,
    cs_net_profit,
    profit_flag,
    profit_rank,
    p_promo_name,
    sm_type,
    cr_return_amount,
    sr_return_amt,
    store_return_date
FROM sales_data
ORDER BY profit_rank ASC, cs_net_profit DESC
LIMIT 100
