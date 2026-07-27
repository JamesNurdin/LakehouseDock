WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_customer_sk,
        cs.cs_sales_price,
        cs.cs_ext_tax,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax BETWEEN 20.00 AND 100.00
      AND cs.cs_sales_price > 50.00
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_sq_ft,
    CASE WHEN fs.cs_ext_tax > 50 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    COALESCE(c.c_first_name, 'Unknown') AS ship_customer_first_name,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = fs.cs_call_center_sk
    ) AS avg_center_profit
FROM filtered_sales fs
INNER JOIN call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN customer c
    ON fs.cs_ship_customer_sk = c.c_customer_sk
WHERE cc.cc_sq_ft > 1000000
  AND cc.cc_mkt_class LIKE '%National%'
  AND c.c_birth_year BETWEEN 1960 AND 1980
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_sq_ft,
    CASE WHEN fs.cs_ext_tax > 50 THEN 'HighTax' ELSE 'LowTax' END,
    c.c_first_name,
    fs.cs_call_center_sk
HAVING SUM(fs.cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
