WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_ext_tax) AS total_tax
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_list_price > 30
      AND ss.ss_quantity >= 2
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ss.ss_store_sk
),

returns_agg AS (
    SELECT
        sr.sr_store_sk,
        SUM(sr.sr_net_loss) AS total_loss,
        r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE r.r_reason_id = 'AAAAAAAADAAAAAAA'
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 10
    GROUP BY sr.sr_store_sk, r.r_reason_desc
),

ranked_sales AS (
    SELECT
        s.s_store_id,
        sa.total_sales,
        ROW_NUMBER() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
        CASE WHEN sa.total_sales > 1000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM sales_agg sa
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
),

ranked_returns AS (
    SELECT
        s.s_store_id,
        ra.total_loss,
        ROW_NUMBER() OVER (ORDER BY ra.total_loss DESC) AS loss_rank,
        CASE WHEN ra.total_loss > 500 THEN 'Big' ELSE 'Small' END AS loss_category
    FROM returns_agg ra
    JOIN store s ON ra.sr_store_sk = s.s_store_sk
    WHERE s.s_country = 'United States'
)

SELECT rs.s_store_id
FROM ranked_sales rs
INTERSECT
SELECT rr.s_store_id
FROM ranked_returns rr
LIMIT 100
