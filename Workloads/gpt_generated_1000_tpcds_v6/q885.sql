WITH cc_filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_gmt_offset
    FROM call_center cc
    WHERE cc.cc_name LIKE '%Center%'
      AND regexp_like(cc.cc_manager, '^A.*')
)
SELECT
    cc.cc_name,
    cc.cc_manager,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(cs.cs_net_profit) > (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_category,
    regexp_extract(cc.cc_manager, '^([A-Za-z]+)', 1) AS manager_first_name,
    CONCAT(CAST(d.d_year AS VARCHAR), ': ', cc.cc_name) AS year_center_label,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
FROM cc_filtered cc
JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
WHERE t.t_shift = 'first'
  AND d.d_year BETWEEN 2000 AND 2002
  AND regexp_like(cc.cc_manager, '.*Smith$')
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    d.d_year,
    regexp_extract(cc.cc_manager, '^([A-Za-z]+)', 1),
    CONCAT(CAST(d.d_year AS VARCHAR), ': ', cc.cc_name)
ORDER BY total_net_profit DESC
LIMIT 100
