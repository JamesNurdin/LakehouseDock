WITH base AS (
    SELECT
        s.s_store_name AS store_name,
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE d_sold.d_year = 2002
      AND d_sold.d_month_seq BETWEEN 1200 AND 1212
      AND cs.cs_quantity > 2
      AND i.inv_quantity_on_hand > 100
      AND s.s_market_manager = 'David Lamontagne'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_desc = 'Damaged'
      )
    GROUP BY s.s_store_name, d_sold.d_year, d_sold.d_month_seq
)
SELECT
    store_name,
    year,
    month_seq,
    total_net_paid,
    total_return_amount,
    distinct_orders,
    avg_sales_price,
    CASE WHEN total_net_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    RANK() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank_by_year
FROM base
ORDER BY profit_rank_by_year
LIMIT 100
