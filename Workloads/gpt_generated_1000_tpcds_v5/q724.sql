WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_state,
        hd.hd_vehicle_count,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND d.d_month_seq IN (1200, 1201, 1202)
      AND t.t_hour BETWEEN 8 AND 20
      AND t.t_am_pm = 'PM'
      AND hd.hd_vehicle_count >= 0
      AND w.w_state IN ('CA', 'TX', 'NY')
      AND cs.cs_quantity > 0
      AND ws.ws_quantity > 0
    GROUP BY d.d_year, d.d_month_seq, w.w_state, hd.hd_vehicle_count
)
SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.w_state,
    sa.hd_vehicle_count,
    sa.catalog_sales_amount,
    sa.web_sales_amount,
    sa.total_profit,
    CASE
        WHEN sa.total_profit > (SELECT AVG(total_profit) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY sa.w_state ORDER BY sa.total_profit DESC) AS state_rank
FROM sales_agg sa
WHERE sa.total_profit > 1000
  AND sa.w_state IN (SELECT DISTINCT w_state FROM warehouse WHERE w_gmt_offset > -5)
ORDER BY sa.total_profit DESC, sa.w_state
LIMIT 100
