WITH filtered_sales AS (
  SELECT
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    cs.cs_quantity,
    cs.cs_bill_customer_sk,
    t.t_hour,
    t.t_shift
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cs.cs_quantity > 50
    AND cs.cs_ship_mode_sk IN (1, 5, 18)
    AND cs.cs_ext_ship_cost > 500
    AND t.t_hour BETWEEN 9 AND 17
    AND t.t_shift IN ('Morning', 'Afternoon')
),
final_agg AS (
  SELECT
    t_hour,
    t_shift,
    COUNT(*) AS sales_count,
    SUM(cs_net_profit) AS total_net_profit,
    AVG(cs_ext_discount_amt) AS avg_discount_amount,
    SUM(cs_quantity) AS total_quantity_sold,
    COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
  FROM filtered_sales
  GROUP BY t_hour, t_shift
  HAVING SUM(cs_quantity) > 1000
)
SELECT *
FROM final_agg
ORDER BY total_net_profit DESC
LIMIT 10
