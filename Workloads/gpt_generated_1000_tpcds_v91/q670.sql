WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales_price,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        COUNT(*) AS total_transactions
    FROM store_sales ss
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_customer_sk = sr.sr_customer_sk
    LEFT OUTER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND ss.ss_ext_tax > 5.0
      AND cs.cs_net_profit > 0
    GROUP BY GROUPING SETS (
        (s.s_store_id, s.s_store_name, r.r_reason_desc),
        (s.s_store_id, s.s_store_name),
        (r.r_reason_desc)
    )
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    COALESCE(agg.r_reason_desc, 'All Reasons') AS reason_desc,
    agg.distinct_customers,
    agg.distinct_sales_price,
    agg.total_sales_price,
    agg.total_return_amount,
    agg.total_transactions,
    AVG(agg.distinct_sales_price) OVER (PARTITION BY agg.s_store_id) AS avg_distinct_sales_price_per_store,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_global_net_profit,
    COUNT(DISTINCT agg.r_reason_desc) OVER (PARTITION BY agg.s_store_id) AS distinct_reason_count
FROM sales_agg agg
WHERE agg.s_store_id NOT IN (
    SELECT s3.s_store_id FROM store s3 WHERE s3.s_state = 'NY'
)
ORDER BY agg.total_sales_price DESC
LIMIT 100
