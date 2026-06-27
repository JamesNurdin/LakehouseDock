-- Promotion performance by month with sales, discounts, profit, returns and inventory
WITH sales_agg AS (
    SELECT
        promotion.p_promo_id AS promo_id,
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        SUM(store_sales.ss_ext_sales_price) AS total_sales,
        SUM(store_sales.ss_ext_discount_amt) AS total_discount,
        SUM(store_sales.ss_net_profit) AS total_profit,
        COUNT(DISTINCT store.s_store_id) AS store_count
    FROM store_sales
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN store ON store_sales.ss_store_sk = store.s_store_sk
    WHERE date_dim.d_date >= DATE '2020-01-01'
      AND date_dim.d_date < DATE '2021-01-01'
    GROUP BY promotion.p_promo_id, date_dim.d_year, date_dim.d_month_seq
),
returns_agg AS (
    SELECT
        promotion.p_promo_id AS promo_id,
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        SUM(store_returns.sr_net_loss) AS total_return_loss
    FROM store_returns
    JOIN store_sales
        ON store_returns.sr_item_sk = store_sales.ss_item_sk
       AND store_returns.sr_store_sk = store_sales.ss_store_sk
       AND store_returns.sr_ticket_number = store_sales.ss_ticket_number
    JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
    JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date >= DATE '2020-01-01'
      AND date_dim.d_date < DATE '2021-01-01'
    GROUP BY promotion.p_promo_id, date_dim.d_year, date_dim.d_month_seq
),
inventory_agg AS (
    SELECT
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        SUM(inventory.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    JOIN date_dim ON inventory.inv_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date >= DATE '2020-01-01'
      AND date_dim.d_date < DATE '2021-01-01'
    GROUP BY date_dim.d_year, date_dim.d_month_seq
)
SELECT
    sales_agg.promo_id,
    sales_agg.year,
    sales_agg.month_seq,
    sales_agg.total_sales,
    sales_agg.total_discount,
    sales_agg.total_profit,
    COALESCE(returns_agg.total_return_loss, 0) AS total_return_loss,
    inventory_agg.total_inventory_qty,
    sales_agg.store_count
FROM sales_agg
LEFT JOIN returns_agg
    ON sales_agg.promo_id = returns_agg.promo_id
   AND sales_agg.year = returns_agg.year
   AND sales_agg.month_seq = returns_agg.month_seq
LEFT JOIN inventory_agg
    ON sales_agg.year = inventory_agg.year
   AND sales_agg.month_seq = inventory_agg.month_seq
ORDER BY sales_agg.total_sales DESC
LIMIT 20
