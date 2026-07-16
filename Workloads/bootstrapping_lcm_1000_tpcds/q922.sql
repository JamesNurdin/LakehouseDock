WITH agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        d_return.d_year AS return_year,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        store.s_store_name,
        store.s_state,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) FILTER (WHERE cr.cr_return_quantity > 0) AS return_count,
        AVG(cs.cs_quantity) AS avg_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_tax) AS total_tax,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity * i.i_wholesale_cost) AS total_wholesale_cost
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store
        ON store.s_closed_date_sk = d_return.d_date_sk
    WHERE d_return.d_year = 2001
      AND i.i_category = 'Books'
    GROUP BY
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        d_return.d_year,
        d_sold.d_year,
        d_ship.d_year,
        store.s_store_name,
        store.s_state
)
SELECT
    agg.i_item_sk,
    agg.i_product_name,
    agg.i_category,
    agg.return_year,
    agg.sold_year,
    agg.ship_year,
    agg.s_store_name,
    agg.s_state,
    agg.total_net_profit,
    agg.distinct_orders,
    agg.total_net_loss,
    agg.return_count,
    agg.avg_quantity_sold,
    agg.total_sales,
    agg.total_tax,
    agg.total_discount,
    agg.total_wholesale_cost,
    ROW_NUMBER() OVER (PARTITION BY agg.i_item_sk ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
