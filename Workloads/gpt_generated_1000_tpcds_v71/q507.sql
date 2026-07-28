WITH filtered_sales AS (
    SELECT
        d.d_year,
        cc.cc_name,
        w.w_warehouse_name,
        c.c_email_address,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
      AND regexp_like(c.c_email_address, '.*@[^@]+\\.com$')
      AND cc.cc_name LIKE '%Center%'
)
SELECT
    d_year,
    cc_name,
    w_warehouse_name,
    CONCAT(cc_name, ' - ', w_warehouse_name) AS cc_warehouse_combo,
    array_agg(DISTINCT regexp_extract(c_email_address, '@(.+)$', 1)) AS email_domains,
    COUNT(*) AS order_count,
    SUM(cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(cs_net_profit) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM filtered_sales
GROUP BY d_year, cc_name, w_warehouse_name
ORDER BY total_profit DESC
LIMIT 100
