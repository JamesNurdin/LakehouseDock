WITH sales_agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_count
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_tax > 0
        AND cs.cs_ext_wholesale_cost >= 1000
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING SUM(cs.cs_net_paid) > (
        SELECT AVG(cs2.cs_net_paid) FROM catalog_sales cs2
    )
),
returns_agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_count
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wp.wp_type = 'product'
        AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
    HAVING SUM(wr.wr_net_loss) > 0
)
SELECT 
    'sales' AS source,
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    s.total_net_paid,
    s.sales_count,
    NULL AS total_net_loss,
    NULL AS returns_count
FROM sales_agg s
UNION ALL
SELECT 
    'returns' AS source,
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    NULL AS total_net_paid,
    NULL AS sales_count,
    r.total_net_loss,
    r.returns_count
FROM returns_agg r
ORDER BY source, total_net_paid DESC NULLS LAST, total_net_loss DESC NULLS LAST
LIMIT 100
