WITH customer_year_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
        SUM(CASE WHEN hd.hd_vehicle_count >= 2 THEN ss.ss_net_profit ELSE 0 END) AS net_profit_with_vehicle
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND d.d_date >= DATE '2002-01-01' AND d.d_date < DATE '2003-01-01'
      AND hd.hd_buy_potential = '>10000'
      AND p.p_channel_email = 'N'
      AND ss.ss_quantity > 2
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
      )
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year
)
SELECT
    cys.c_customer_id,
    cys.c_first_name,
    cys.c_last_name,
    cys.d_year,
    cys.total_net_profit,
    cys.total_quantity,
    cys.avg_sales_price,
    cys.distinct_items_sold,
    cys.net_profit_with_vehicle,
    ROW_NUMBER() OVER (PARTITION BY cys.d_year ORDER BY cys.total_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (PARTITION BY cys.d_year ORDER BY cys.total_quantity DESC) AS quantity_rank
FROM customer_year_sales cys
ORDER BY cys.total_net_profit DESC
LIMIT 100
