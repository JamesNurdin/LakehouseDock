WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_list_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_list_price BETWEEN 50 AND 260
      AND cs.cs_quantity >= 2
      AND cs.cs_ship_date_sk BETWEEN 2450866 AND 2450890
      AND cs.cs_net_paid_inc_ship_tax > 500
      AND cs.cs_net_profit > 0
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    t_sold.t_hour,
    COUNT(DISTINCT f.cs_order_number) AS order_cnt,
    SUM(f.cs_ext_sales_price) AS total_sales,
    AVG(f.cs_net_profit) AS avg_profit,
    MIN(f.cs_list_price) AS min_list_price,
    MAX(f.cs_list_price) AS max_list_price,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    SUM(sr.sr_return_tax) AS total_return_tax,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt
FROM filtered_sales f
JOIN date_dim d_sold
    ON f.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON f.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON f.cs_ship_date_sk = d_ship.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
   AND sr.sr_return_time_sk = t_sold.t_time_sk
WHERE d_sold.d_current_year = 'Y'
  AND d_sold.d_qoy = 2
  AND t_sold.t_hour BETWEEN 9 AND 17
  AND sr.sr_refunded_cash > 0
  AND sr.sr_return_tax >= 0
  AND sr.sr_net_loss < 500
GROUP BY d_sold.d_year, d_sold.d_month_seq, t_sold.t_hour
ORDER BY total_sales DESC
LIMIT 100
