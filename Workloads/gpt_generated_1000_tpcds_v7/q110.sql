WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_paid_inc_ship > 500
      AND cs.cs_net_paid > 1000
)
SELECT
    d.d_quarter_name,
    sm.sm_code,
    SUM(fs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
    COUNT(*) AS order_count,
    AVG(fs.cs_net_paid_inc_ship) AS avg_net_paid_inc_ship,
    CASE
        WHEN SUM(fs.cs_net_paid_inc_ship) > (
            SELECT AVG(cs.cs_net_paid_inc_ship)
            FROM catalog_sales cs
            WHERE cs.cs_quantity > 1
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_vs_overall,
    RANK() OVER (PARTITION BY sm.sm_code ORDER BY SUM(fs.cs_net_paid_inc_ship) DESC) AS rank_by_shipmode
FROM filtered_sales fs
JOIN date_dim d
  ON fs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
  ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_quarter_name IN ('1901Q3', '1904Q2')
  AND sm.sm_code IN ('AIR', 'SEA')
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = fs.cs_ship_mode_sk
          AND sm2.sm_contract LIKE 'I3u%'
    )
GROUP BY d.d_quarter_name, sm.sm_code
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
