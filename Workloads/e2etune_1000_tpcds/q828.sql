WITH hourly_stats AS (
    SELECT
        t.t_hour,
        t.t_am_pm,
        t.t_shift,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales_price
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_ext_discount_amt > 0
      AND ss.ss_customer_sk IN (
          SELECT wp_customer_sk
          FROM web_page
          WHERE wp_type = 'product'
            AND wp_image_count > 0
      )
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY t.t_hour, t.t_am_pm, t.t_shift
)
SELECT
    h.t_hour,
    h.t_am_pm,
    h.t_shift,
    h.sales_cnt,
    h.total_net_profit,
    h.avg_discount,
    h.total_quantity,
    h.total_sales_price,
    RANK() OVER (ORDER BY h.total_net_profit DESC) AS profit_rank
FROM hourly_stats h
WHERE h.sales_cnt > 100
ORDER BY h.total_net_profit DESC
LIMIT 15
