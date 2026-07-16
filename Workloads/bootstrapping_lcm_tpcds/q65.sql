SELECT
    d_sold.d_year AS year,
    d_sold.d_month_seq AS month_seq,
    d_sold.d_quarter_name AS quarter,
    web_site.web_market_manager,
    COUNT(DISTINCT web_sales.ws_order_number) AS distinct_orders,
    SUM(web_sales.ws_net_profit) AS total_net_profit,
    SUM(web_sales.ws_net_profit) FILTER (WHERE d_ship.d_weekend = 'Y') AS weekend_ship_profit,
    SUM(web_sales.ws_net_profit) FILTER (WHERE d_sold.d_holiday IS NOT NULL) AS holiday_profit,
    AVG(inventory.inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT store.s_store_id) AS closed_stores,
    COUNT(DISTINCT CASE
        WHEN d_open.d_year = d_sold.d_year AND d_open.d_month_seq = d_sold.d_month_seq
        THEN web_site.web_site_id
    END) AS sites_opened_this_month,
    COUNT(DISTINCT CASE
        WHEN d_close.d_year = d_sold.d_year AND d_close.d_month_seq = d_sold.d_month_seq
        THEN web_site.web_site_id
    END) AS sites_closed_this_month,
    SUM(CASE
        WHEN web_site.web_tax_percentage > 5.00 THEN web_sales.ws_net_profit
        ELSE 0
    END) AS high_tax_profit,
    SUM(web_sales.ws_net_profit) / NULLIF(AVG(inventory.inv_quantity_on_hand), 0) AS profit_per_inventory
FROM web_sales
JOIN date_dim AS d_sold
    ON web_sales.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim AS d_ship
    ON web_sales.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site
    ON web_sales.ws_web_site_sk = web_site.web_site_sk
JOIN date_dim AS d_open
    ON web_site.web_open_date_sk = d_open.d_date_sk
JOIN date_dim AS d_close
    ON web_site.web_close_date_sk = d_close.d_date_sk
JOIN date_dim AS d_store
    ON web_sales.ws_sold_date_sk = d_store.d_date_sk
JOIN store
    ON store.s_closed_date_sk = d_store.d_date_sk
JOIN inventory
    ON inventory.inv_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_quarter_name,
    web_site.web_market_manager
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq
LIMIT 100
