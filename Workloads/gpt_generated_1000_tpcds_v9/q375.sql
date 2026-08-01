/*
Goal: Analyze total sales, store and web return losses, and inventory levels by year, household buying potential, catalog page type, and return reasons. The query filters on specific demographic, catalog, and page attributes, aggregates key financial measures, filters groups by sales volume, orders by total sales, and returns the top 100 combinations.
*/
WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inv_quantity,
        AVG(inv_quantity_on_hand) AS avg_inv_quantity,
        MAX(inv_quantity_on_hand) AS max_inv_quantity,
        MIN(inv_quantity_on_hand) AS min_inv_quantity
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk
)
SELECT
    d.d_year,
    hd.hd_buy_potential,
    cp.cp_type,
    reason_sr.r_reason_desc AS store_return_reason,
    reason_wr.r_reason_desc AS web_return_reason,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(inv_agg.total_inv_quantity) AS total_inventory_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason reason_sr
    ON sr.sr_reason_sk = reason_sr.r_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason reason_wr
    ON wr.wr_reason_sk = reason_wr.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND hd.hd_buy_potential = '1001-5000'
  AND hd.hd_vehicle_count >= 1
  AND cp.cp_catalog_number BETWEEN 100 AND 200
  AND reason_sr.r_reason_desc LIKE '%damaged%'
  AND wp.wp_type = 'Content'
GROUP BY
    d.d_year,
    hd.hd_buy_potential,
    cp.cp_type,
    reason_sr.r_reason_desc,
    reason_wr.r_reason_desc
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
