WITH item_patterns AS (
    SELECT
        i.i_item_sk,
        i.i_color,
        i.i_formulation,
        SUBSTR(i.i_color, 1, 3) AS color_prefix,
        REGEXP_EXTRACT(i.i_formulation, '\\d+') AS first_numeric,
        CASE
            WHEN REGEXP_LIKE(i.i_color, '^roy') THEN 'royal'
            WHEN REGEXP_LIKE(i.i_color, '^yellow') THEN 'yellow'
            ELSE 'other'
        END AS color_group
    FROM item i
    WHERE REGEXP_LIKE(i.i_color, 'roy|yellow')
      AND REGEXP_LIKE(i.i_formulation, '\\d')
)
SELECT
    s.s_store_name,
    CONCAT(s.s_store_name, ' - ', w.w_warehouse_name) AS store_warehouse,
    ip.color_group,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE REGEXP_LIKE(i2.i_color, '^roy')
    ) AS avg_royal_color_profit
FROM catalog_sales cs
JOIN item_patterns ip ON cs.cs_item_sk = ip.i_item_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_item_sk = ip.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE w.w_warehouse_name LIKE '%National%'
  AND EXISTS (
      SELECT 1
      FROM store_returns sr_ex
      WHERE sr_ex.sr_store_sk = s.s_store_sk
        AND sr_ex.sr_fee > 20
  )
GROUP BY s.s_store_name, w.w_warehouse_name, ip.color_group
ORDER BY total_net_profit DESC
LIMIT 100
