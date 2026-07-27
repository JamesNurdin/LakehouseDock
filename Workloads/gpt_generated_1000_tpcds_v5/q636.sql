WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        'sales' AS source_type,
        SUM(ss.ss_net_profit) AS total_amount,
        CASE
            WHEN SUM(ss.ss_net_profit) > (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) THEN 'high'
            WHEN SUM(ss.ss_net_profit) > (SELECT avg(ss2.ss_net_profit) * 0.5 FROM store_sales ss2) THEN 'medium'
            ELSE 'low'
        END AS category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_rec_start_date >= DATE '2000-01-01'
      AND c.c_email_address LIKE '%@%.com%'
      AND hd.hd_vehicle_count > 1
    GROUP BY s.s_store_id, s.s_store_name
),
returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        'returns' AS source_type,
        SUM(sr.sr_net_loss) AS total_amount,
        CASE
            WHEN SUM(sr.sr_net_loss) > 50000 THEN 'high'
            WHEN SUM(sr.sr_net_loss) > 20000 THEN 'medium'
            ELSE 'low'
        END AS category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc LIKE '%Damaged%'
      AND c.c_preferred_cust_flag = 'Y'
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_store_sk = s.s_store_sk
            AND ss2.ss_sold_date_sk = sr.sr_returned_date_sk
      )
    GROUP BY s.s_store_id, s.s_store_name
),
combined AS (
    SELECT s_store_id, s_store_name, source_type, total_amount, category
    FROM sales_agg
    UNION ALL
    SELECT s_store_id, s_store_name, source_type, total_amount, category
    FROM returns_agg
)
SELECT
    c.s_store_id,
    c.s_store_name,
    c.source_type,
    c.total_amount,
    c.category,
    c.total_amount - (
        SELECT avg(t.total_amount)
        FROM (
            SELECT total_amount FROM sales_agg
            UNION ALL
            SELECT total_amount FROM returns_agg
        ) t
    ) AS diff_from_avg
FROM combined c
ORDER BY c.s_store_name ASC, c.total_amount DESC
LIMIT 100
