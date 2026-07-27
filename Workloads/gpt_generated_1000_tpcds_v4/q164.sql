WITH warehouse_avg AS (
    SELECT cs.cs_warehouse_sk AS w_warehouse_sk,
           avg(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk
)
SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    concat(i.i_brand, ' - ', i.i_category) AS brand_category,
    w.w_warehouse_name AS warehouse_name,
    sum(cs.cs_net_profit) AS total_net_profit,
    count(*) AS sales_cnt,
    max(d.d_year) AS latest_year
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_avg wa
  ON cs.cs_warehouse_sk = wa.w_warehouse_sk
WHERE regexp_like(i.i_item_desc, '(?i)new')
  AND cc.cc_name LIKE 'A%'
  AND sm.sm_code LIKE 'AIR%'
  AND cs.cs_net_profit > wa.avg_profit
  AND d.d_year BETWEEN 2001 AND 2002
GROUP BY
    i.i_category,
    i.i_brand,
    concat(i.i_brand, ' - ', i.i_category),
    w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
