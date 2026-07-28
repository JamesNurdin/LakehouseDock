WITH ss_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_quantity) AS avg_qty,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_band
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 20.00
      AND ss.ss_coupon_amt = 0.00
      AND ss.ss_quantity >= 1
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk
)
SELECT
    d.d_date,
    t.t_hour,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    s.s_store_name,
    p.p_promo_name,
    ss_agg.total_sales,
    ss_agg.total_profit,
    ss_agg.sales_cnt,
    ss_agg.avg_qty,
    ss_agg.sales_band,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss_agg.total_sales DESC) AS store_sales_rank,
    SUM(wr.wr_return_quantity) OVER (PARTITION BY s.s_store_sk) AS total_returns_by_store
FROM ss_agg
JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss_agg.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
    AND wr.wr_returning_customer_sk = c.c_customer_sk
    AND wr.wr_returning_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND t.t_hour BETWEEN 8 AND 12
  AND ca.ca_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND wr.wr_return_amt > 100.00
  AND wr.wr_return_tax = 0.00
ORDER BY ss_agg.total_sales DESC
LIMIT 100
