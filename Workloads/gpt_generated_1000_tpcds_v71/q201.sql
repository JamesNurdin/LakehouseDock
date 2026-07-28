WITH filtered AS (
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_quantity,
           ss_net_paid,
           ss_net_profit
    FROM tpcds.store_sales
    WHERE ss_list_price > 20.00
      AND ss_net_paid BETWEEN 500.00 AND 3000.00
)
SELECT filtered.ss_sold_date_sk,
       COUNT(*) AS sales_cnt,
       SUM(filtered.ss_quantity) AS total_qty,
       SUM(filtered.ss_net_paid) AS total_net_paid,
       SUM(filtered.ss_net_profit) AS total_net_profit
FROM filtered
GROUP BY filtered.ss_sold_date_sk
ORDER BY filtered.ss_sold_date_sk
LIMIT 100
