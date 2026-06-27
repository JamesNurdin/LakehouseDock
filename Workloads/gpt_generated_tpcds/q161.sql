WITH sales AS (
    SELECT
        cs_sold_date_sk,
        cs_order_number,
        cs_bill_customer_sk,
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        cs_net_profit,
        cs_ship_mode_sk,
        cs_promo_sk,
        cs_item_sk
    FROM catalog_sales
),
returns AS (
    SELECT
        cr_order_number,
        cr_net_loss
    FROM catalog_returns
)
SELECT
    date_dim.d_year,
    date_dim.d_month_seq,
    promotion.p_promo_id,
    ship_mode.sm_type,
    item.i_category,
    item.i_brand,
    sum(sales.cs_ext_sales_price) AS total_sales,
    sum(sales.cs_quantity) AS total_quantity,
    sum(sales.cs_ext_discount_amt) AS total_discount,
    sum(sales.cs_net_profit) AS total_net_profit,
    sum(coalesce(returns.cr_net_loss, 0)) AS total_return_loss,
    sum(sales.cs_net_profit) - sum(coalesce(returns.cr_net_loss, 0)) AS net_profit_after_returns,
    count(distinct sales.cs_bill_customer_sk) AS distinct_customers
FROM sales
JOIN date_dim ON sales.cs_sold_date_sk = date_dim.d_date_sk
JOIN promotion ON sales.cs_promo_sk = promotion.p_promo_sk
JOIN ship_mode ON sales.cs_ship_mode_sk = ship_mode.sm_ship_mode_sk
JOIN item ON sales.cs_item_sk = item.i_item_sk
LEFT JOIN returns ON sales.cs_order_number = returns.cr_order_number
WHERE date_dim.d_date >= DATE '2001-01-01' AND date_dim.d_date < DATE '2002-01-01'
GROUP BY
    date_dim.d_year,
    date_dim.d_month_seq,
    promotion.p_promo_id,
    ship_mode.sm_type,
    item.i_category,
    item.i_brand
ORDER BY date_dim.d_year, date_dim.d_month_seq, total_sales DESC
LIMIT 100
