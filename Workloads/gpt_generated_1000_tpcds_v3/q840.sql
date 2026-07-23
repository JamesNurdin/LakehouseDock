WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    t_sales.t_hour,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS total_positive_profit,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    inv_agg.total_on_hand,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN item i2 ON ss2.ss_item_sk = i2.i_item_sk
        WHERE i2.i_brand = i.i_brand
    ) AS brand_avg_profit
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
WHERE ss.ss_sold_date_sk BETWEEN 2451010 AND 2451019
  AND ss.ss_net_paid > 1000
  AND i.i_current_price BETWEEN 20 AND 200
  AND t_sales.t_hour BETWEEN 9 AND 17
  AND r.r_reason_desc LIKE '%price%'
GROUP BY i.i_brand,
         i.i_category,
         r.r_reason_desc,
         t_sales.t_hour,
         inv_agg.total_on_hand
HAVING SUM(ss.ss_net_paid) > 5000
ORDER BY total_sales DESC,
         avg_profit DESC
LIMIT 100
