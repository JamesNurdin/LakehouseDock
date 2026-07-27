WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_coupon_amt,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ship_customer_sk,
        d_sold.d_fy_year,
        d_sold.d_current_month,
        d_ship.d_fy_year AS ship_fy_year,
        d_ship.d_current_month AS ship_current_month,
        s.s_store_id,
        s.s_store_name,
        s.s_market_id,
        s.s_division_id,
        s.s_tax_percentage
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_fy_year = 1910
      AND d_sold.d_current_month = 'Y'
      AND d_ship.d_fy_year = 1909
      AND d_ship.d_current_month = 'N'
      AND cs.cs_coupon_amt > 1000
      AND cs.cs_quantity BETWEEN 1 AND 5
      AND cs.cs_net_profit > 0
      AND cs.cs_ship_customer_sk IN (7612033, 7473413)
      AND s.s_market_id IN (3, 4, 7)
      AND s.s_division_id = 1
      AND s.s_tax_percentage < 5
      AND EXISTS (
          SELECT 1
          FROM store s2
          WHERE s2.s_market_id = s.s_market_id
            AND s2.s_tax_percentage < 5
            AND s2.s_store_id <> s.s_store_id
      )
),
store_profit AS (
    SELECT
        s_store_id,
        s_store_name,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM filtered_sales
    GROUP BY s_store_id, s_store_name
)
SELECT
    sp.s_store_id,
    sp.s_store_name,
    sp.total_profit,
    RANK() OVER (ORDER BY sp.total_profit DESC) AS profit_rank,
    sp.sales_count
FROM store_profit sp
ORDER BY sp.total_profit DESC
LIMIT 100
