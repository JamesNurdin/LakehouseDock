WITH daily_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        store_sales.ss_store_sk AS store_sk,
        SUM(store_sales.ss_net_paid) AS total_store_sales,
        SUM(store_sales.ss_net_profit) AS total_store_profit,
        SUM(store_returns.sr_refunded_cash) AS total_refunds,
        SUM(store_returns.sr_net_loss) AS total_return_loss,
        SUM(web_sales.ws_net_paid) AS total_web_sales,
        SUM(web_sales.ws_net_profit) AS total_web_profit,
        SUM(inventory.inv_quantity_on_hand) AS total_inventory_qty
    FROM store_sales
    INNER JOIN date_dim d
        ON store_sales.ss_sold_date_sk = d.d_date_sk
    INNER JOIN store_returns
        ON store_returns.sr_returned_date_sk = d.d_date_sk
        AND store_returns.sr_item_sk = store_sales.ss_item_sk
        AND store_returns.sr_ticket_number = store_sales.ss_ticket_number
    INNER JOIN web_sales
        ON web_sales.ws_sold_date_sk = d.d_date_sk
    INNER JOIN ship_mode
        ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    INNER JOIN inventory
        ON inventory.inv_date_sk = d.d_date_sk
    INNER JOIN catalog_page
        ON catalog_page.cp_start_date_sk = d.d_date_sk
    WHERE
        d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        AND store_sales.ss_sales_price > 20
        AND ship_mode.sm_carrier = 'UPS'
        AND inventory.inv_quantity_on_hand > 0
        AND catalog_page.cp_department = 'Electronics'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        store_sales.ss_store_sk
)
SELECT
    profit_category,
    AVG(total_store_sales) AS avg_store_sales,
    AVG(total_web_sales) AS avg_web_sales,
    SUM(total_store_profit + total_web_profit - total_refunds - total_return_loss) AS total_net_profit
FROM (
    SELECT
        d_year,
        d_month_seq,
        store_sk,
        total_store_sales,
        total_store_profit,
        total_refunds,
        total_return_loss,
        total_web_sales,
        total_web_profit,
        total_inventory_qty,
        CASE
            WHEN (total_store_profit + total_web_profit - total_refunds - total_return_loss) > 50000 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM daily_agg
) AS agg
GROUP BY profit_category
HAVING AVG(total_store_sales) > 1000
ORDER BY avg_store_sales DESC
LIMIT 100
