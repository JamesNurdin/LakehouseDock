WITH filtered_sales AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_paid_inc_tax,
        ss.ss_list_price,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_list_price >= 50
      AND ss.ss_promo_sk IN (602, 194)
      AND ss.ss_quantity BETWEEN 1 AND 5
)
SELECT
    c.c_customer_id,
    c.c_current_cdemo_sk,
    t.t_hour,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    COUNT(DISTINCT fs.ss_sold_time_sk) AS distinct_sale_times,
    MIN(fs.ss_list_price) AS min_list_price,
    MAX(fs.ss_list_price) AS max_list_price,
    SUM(CASE WHEN wr.wr_return_amt > 200 THEN wr.wr_return_amt ELSE 0 END) AS total_high_returns,
    ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_customer_id) AS demo_rank
FROM filtered_sales fs
JOIN customer c
    ON fs.ss_customer_sk = c.c_customer_sk
JOIN time_dim t
    ON fs.ss_sold_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
WHERE c.c_current_cdemo_sk = 442697
  AND t.t_hour BETWEEN 9 AND 17
  AND wr.wr_reversed_charge < 200
  AND wr.wr_refunded_cash > 100
  AND wr.wr_return_quantity > 0
  AND wr.wr_fee < 50
GROUP BY
    c.c_customer_id,
    c.c_current_cdemo_sk,
    t.t_hour
HAVING SUM(fs.ss_ext_sales_price) > 5000
ORDER BY total_sales DESC, c.c_customer_id
LIMIT 100
