/*
Goal: Identify the top 10 sales orders per profit‑tier (High/Medium/Low) for afternoon (PM) sales that were billed to condo addresses, rank them by net profit, and compare each order's profit to the overall average profit.
*/
WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        td.t_hour,
        td.t_am_pm,
        ca.ca_state,
        ca.ca_location_type,
        CASE
            WHEN cs.cs_net_profit >= 500 THEN 'High'
            WHEN cs.cs_net_profit >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS profit_bucket,
        ROW_NUMBER() OVER (
            PARTITION BY CASE
                WHEN cs.cs_net_profit >= 500 THEN 'High'
                WHEN cs.cs_net_profit >= 100 THEN 'Medium'
                ELSE 'Low'
            END
            ORDER BY cs.cs_net_profit DESC
        ) AS profit_rank,
        CASE
            WHEN cs.cs_net_profit > (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2)
                THEN 'AboveAvg'
            ELSE 'BelowAvg'
        END AS profit_vs_avg
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND td.t_am_pm = 'PM'
      AND ca.ca_location_type = 'condo'
      AND cs.cs_quantity >= 2
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs_ex
          WHERE cs_ex.cs_order_number = cs.cs_order_number
            AND cs_ex.cs_net_profit < 0
      )
)
SELECT
    cs_order_number,
    cs_net_profit,
    profit_bucket,
    profit_rank,
    profit_vs_avg,
    t_hour,
    ca_state,
    ca_location_type,
    cs_ext_sales_price,
    cs_quantity
FROM filtered_sales
WHERE profit_rank <= 10
ORDER BY profit_bucket ASC, profit_rank ASC, cs_net_profit DESC
LIMIT 100
