WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_net_profit,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_month_seq AS ship_month,
        cp.cp_department,
        cp.cp_catalog_page_number,
        inv.inv_quantity_on_hand,
        sr.sr_return_amt_inc_tax,
        CASE 
            WHEN ws.ws_net_profit > 1000 THEN 'HIGH'
            WHEN ws.ws_net_profit > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk                     -- join 1
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk                     -- join 2
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk                    -- join 3
    JOIN catalog_page cp_end ON cp_end.cp_end_date_sk = d_ship.d_date_sk               -- join 4 (reuse catalog_page)
    JOIN sampled_inventory inv ON inv.inv_date_sk = d_ship.d_date_sk                  -- join 5
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk                -- join 6
    JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk             -- join 7 (reuse date_dim)
    JOIN date_dim d_extra ON ws.ws_sold_date_sk = d_extra.d_date_sk                  -- join 8 (reuse date_dim)
    JOIN date_dim d_inventory ON inv.inv_date_sk = d_inventory.d_date_sk            -- join 9 (reuse date_dim)
)
SELECT 
    sold_year,
    sold_month,
    profit_category,
    COUNT(*) AS order_cnt,
    SUM(ws_net_paid_inc_ship_tax) AS total_paid,
    AVG(ws_net_profit) AS avg_profit,
    SUM(CASE WHEN ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales) THEN 1 ELSE 0 END) AS high_profit_orders
FROM joined_data
WHERE ws_order_number NOT IN (
    SELECT ws_order_number FROM web_sales WHERE ws_net_profit < 0
)
GROUP BY GROUPING SETS (
    (sold_year, sold_month, profit_category),
    (sold_year, profit_category),
    (profit_category)
)
ORDER BY sold_year DESC, sold_month DESC, profit_category
LIMIT 100
