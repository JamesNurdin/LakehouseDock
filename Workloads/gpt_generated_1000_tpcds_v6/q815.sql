WITH sales AS (
    SELECT
        ca.ca_city,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(CAST(regexp_extract(ca.ca_suite_number, '\\d+') AS integer)) AS avg_suite_number
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_suite_number, '^Suite [0-9]+')
      AND ca.ca_city LIKE '%Hope%'
    GROUP BY ca.ca_city, d.d_year, d.d_month_seq
),
inventory_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.ca_city,
    s.d_year,
    s.d_month_seq,
    s.total_net_profit,
    s.avg_suite_number,
    i.avg_inventory_qty
FROM sales s
LEFT JOIN inventory_month i
    ON s.d_year = i.d_year
   AND s.d_month_seq = i.d_month_seq
ORDER BY s.total_net_profit DESC
LIMIT 100
