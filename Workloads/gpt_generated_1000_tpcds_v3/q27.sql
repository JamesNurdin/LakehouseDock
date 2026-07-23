WITH distinct_sales AS (
  SELECT DISTINCT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_coupon_amt,
    sr.sr_fee,
    sr.sr_return_ship_cost,
    sr.sr_store_credit,
    p.p_promo_name AS p_promo_name,
    w.w_warehouse_name AS w_warehouse_name,
    d_sold.d_year AS d_year
  FROM catalog_sales cs
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
   AND sr.sr_return_time_sk = t_sold.t_time_sk
  JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
  JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
  WHERE cs.cs_coupon_amt > 500
    AND sr.sr_fee > 30
    AND d_sold.d_year = 2001
    AND p.p_discount_active = 'Y'
),
sales_agg AS (
  SELECT
    p_promo_name AS promo_name,
    w_warehouse_name AS warehouse_name,
    d_year,
    SUM(cs_ext_sales_price) AS sum_sales,
    SUM(cs_net_profit) AS sum_profit,
    SUM(sr_fee + sr_return_ship_cost + sr_store_credit) AS sum_returns,
    COUNT(*) AS order_cnt
  FROM distinct_sales
  GROUP BY p_promo_name, w_warehouse_name, d_year
)
SELECT
  promo_name,
  SUM(sum_sales) AS total_sales,
  SUM(sum_profit) AS total_profit,
  SUM(sum_returns) AS total_returns,
  SUM(order_cnt) AS total_orders,
  AVG(sum_profit) AS avg_profit_per_warehouse
FROM sales_agg
GROUP BY promo_name
HAVING SUM(sum_sales) > 20000
ORDER BY total_profit DESC
LIMIT 100
