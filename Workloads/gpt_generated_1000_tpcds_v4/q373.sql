WITH agg AS (
    SELECT
        warehouse.w_warehouse_id,
        date_dim.d_year,
        SUM(catalog_sales.cs_net_profit) AS sum_catalog_profit,
        SUM(web_sales.ws_net_profit) AS sum_web_profit,
        SUM(store_returns.sr_net_loss) AS sum_return_loss,
        SUM(inventory.inv_quantity_on_hand) AS sum_inventory_qty,
        COUNT(DISTINCT catalog_page.cp_catalog_page_id) AS distinct_pages
    FROM date_dim
    JOIN catalog_page
      ON catalog_page.cp_start_date_sk = date_dim.d_date_sk
    JOIN catalog_sales
      ON catalog_sales.cs_catalog_page_sk = catalog_page.cp_catalog_page_sk
    JOIN catalog_returns
      ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
    JOIN warehouse
      ON catalog_sales.cs_warehouse_sk = warehouse.w_warehouse_sk
    JOIN inventory
      ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
     AND inventory.inv_date_sk = date_dim.d_date_sk
    JOIN promotion
      ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
    JOIN store_returns
      ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN web_page
      ON web_page.wp_creation_date_sk = date_dim.d_date_sk
    JOIN web_sales
      ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
    WHERE date_dim.d_year = 2001
      AND catalog_page.cp_department = 'Electronics'
      AND catalog_sales.cs_quantity > 5
      AND catalog_sales.cs_net_profit > 1000
      AND promotion.p_discount_active = 'Y'
      AND warehouse.w_warehouse_sq_ft > 500000
      AND store_returns.sr_refunded_cash < 500
      AND web_sales.ws_ext_ship_cost BETWEEN 100 AND 2000
      AND inventory.inv_quantity_on_hand > 0
    GROUP BY warehouse.w_warehouse_id, date_dim.d_year
)
SELECT
    w_warehouse_id,
    d_year,
    sum_catalog_profit,
    sum_web_profit,
    sum_return_loss,
    sum_inventory_qty,
    distinct_pages,
    (sum_catalog_profit + sum_web_profit - sum_return_loss) AS net_total_profit,
    (sum_catalog_profit + sum_web_profit) / NULLIF(distinct_pages, 0) AS profit_per_page
FROM agg
WHERE (sum_catalog_profit + sum_web_profit - sum_return_loss) > 5000
ORDER BY net_total_profit DESC
LIMIT 100
