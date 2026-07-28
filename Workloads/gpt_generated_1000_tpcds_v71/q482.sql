WITH sales_enriched AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        d.d_year,
        ws.ws_net_profit,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@(.+)$') AS email_domain
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@[^@]+\\.com$')
      AND w.w_city LIKE '%York%'
)
SELECT
    w_warehouse_id,
    w_warehouse_name,
    email_domain,
    d_year,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    CASE
        WHEN SUM(ws_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(ws_net_profit) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM sales_enriched
GROUP BY w_warehouse_id, w_warehouse_name, email_domain, d_year
ORDER BY total_net_profit DESC
LIMIT 100
