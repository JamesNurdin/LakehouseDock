WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY cs.cs_sold_date_sk, cs.cs_warehouse_sk
)
SELECT
    d.d_date,
    w.w_warehouse_name,
    s.total_sales_net_paid,
    s.sales_cnt,
    SUM(r.sr_net_loss) AS total_return_loss,
    COUNT(r.sr_ticket_number) AS return_cnt,
    AVG(r.sr_store_credit) AS avg_store_credit
FROM sales_agg s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns r ON r.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON r.sr_return_time_sk = t.t_time_sk
JOIN customer_address ca ON r.sr_addr_sk = ca.ca_address_sk
WHERE
    w.w_city = 'Fairview'
    AND t.t_hour BETWEEN 9 AND 17
    AND r.sr_store_credit > 20
GROUP BY
    d.d_date,
    w.w_warehouse_name,
    s.total_sales_net_paid,
    s.sales_cnt
HAVING
    SUM(r.sr_net_loss) > 100
ORDER BY
    d.d_date DESC,
    w.w_warehouse_name
LIMIT 100
