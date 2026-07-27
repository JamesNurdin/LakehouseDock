WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        d.d_date,
        d.d_year,
        d.d_fy_week_seq
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND cs.cs_net_paid_inc_ship_tax > 2000
      AND cs.cs_ship_mode_sk IN (18, 11, 6)
      AND d.d_fy_week_seq = 10
)
SELECT
    cc.cc_name,
    i.i_category,
    ws.web_state,
    f.d_year,
    SUM(f.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(f.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT f.cs_order_number) AS order_cnt,
    CASE WHEN SUM(f.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
FROM filtered_sales f
JOIN call_center cc
    ON f.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON f.cs_item_sk = i.i_item_sk
JOIN web_site ws
    ON ws.web_open_date_sk = f.cs_sold_date_sk
WHERE cc.cc_state = 'CA'
  AND i.i_category = 'Electronics'
  AND ws.web_county = 'Bronx County'
GROUP BY cc.cc_name, i.i_category, ws.web_state, f.d_year
ORDER BY total_net_paid DESC
LIMIT 100
