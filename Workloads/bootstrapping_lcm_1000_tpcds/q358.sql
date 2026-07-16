WITH sales_returns AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        d_ship.d_week_seq AS ship_week_seq,
        d_ret.d_holiday AS return_holiday,
        s.s_store_name AS store_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT cr.cr_return_quantity) AS distinct_return_quantities
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_week_seq,
        d_ret.d_holiday,
        s.s_store_name
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    sold_year,
    sold_month_seq,
    ship_week_seq,
    return_holiday,
    store_name,
    total_net_paid,
    total_discount,
    total_return_amount,
    total_net_loss,
    total_net_profit,
    distinct_orders,
    distinct_return_quantities,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_returns
ORDER BY sold_year, profit_rank
LIMIT 100
