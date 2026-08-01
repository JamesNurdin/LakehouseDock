WITH sales_agg AS (
    SELECT
        'sales' AS source,
        c.c_customer_id AS customer_id,
        SUM(cs.cs_net_paid) AS total_amount,
        COUNT(DISTINCT cs.cs_order_number) AS txn_count,
        regexp_extract(p.p_channel_details, '(\\w+)', 1) AS extracted_word,
        CONCAT('Promo-', SUBSTRING(p.p_channel_details, 1, 5)) AS fragment
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(p.p_channel_details, '(?i)old')
      AND p.p_channel_demo = 'N'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2452520
    GROUP BY
        c.c_customer_id,
        regexp_extract(p.p_channel_details, '(\\w+)', 1),
        CONCAT('Promo-', SUBSTRING(p.p_channel_details, 1, 5))
),
returns_agg AS (
    SELECT
        'returns' AS source,
        c.c_customer_id AS customer_id,
        SUM(wr.wr_net_loss) AS total_amount,
        COUNT(DISTINCT wr.wr_order_number) AS txn_count,
        CAST(NULL AS VARCHAR) AS extracted_word,
        CONCAT('Reason-', SUBSTRING(r.r_reason_desc, 1, 5)) AS fragment
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)working')
      AND r.r_reason_desc LIKE '%size%'
    GROUP BY
        c.c_customer_id,
        CONCAT('Reason-', SUBSTRING(r.r_reason_desc, 1, 5))
)
SELECT *
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) AS combined
ORDER BY combined.total_amount DESC
LIMIT 100
