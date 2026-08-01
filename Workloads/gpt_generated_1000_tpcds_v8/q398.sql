WITH date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1 AND 12
),
intersect_stores AS (
    SELECT s.s_store_id
    FROM store s
    WHERE s.s_state = 'CA'
    INTERSECT
    SELECT s2.s_store_id
    FROM store s2
    JOIN store_returns sr ON sr.sr_store_sk = s2.s_store_sk
    WHERE sr.sr_return_quantity > 0
),
except_stores AS (
    SELECT s.s_store_id
    FROM store s
    WHERE s.s_state = 'TX'
    EXCEPT
    SELECT s2.s_store_id
    FROM store s2
    JOIN store_returns sr ON sr.sr_store_sk = s2.s_store_sk
    WHERE sr.sr_return_quantity > 0
),
aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        s.s_store_id,
        p.p_promo_id,
        c.c_customer_sk,
        c.c_email_address,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        CASE WHEN SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        lc.distinct_customers
    FROM date_filtered d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT cs_inner.cs_bill_customer_sk) AS distinct_customers
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_sold_date_sk = d.d_date_sk
    ) lc
    WHERE cs.cs_quantity > (
        SELECT AVG(cs_avg.cs_quantity)
        FROM catalog_sales cs_avg
        WHERE cs_avg.cs_sold_date_sk = d.d_date_sk
    )
      AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk = d.d_date_sk
      )
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, d.d_date_sk, s.s_store_id, p.p_promo_id, c.c_customer_sk, c.c_email_address, lc.distinct_customers),
        (d.d_year, d.d_month_seq, d.d_date_sk, s.s_store_id, lc.distinct_customers),
        (d.d_year, d.d_month_seq, d.d_date_sk)
    )
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_id,
    a.p_promo_id,
    a.total_sales,
    a.total_returns,
    a.profit_flag,
    ROW_NUMBER() OVER (PARTITION BY a.d_month_seq ORDER BY a.total_sales DESC) AS sales_rank,
    (
        SELECT MAX(sr3.sr_return_amt)
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = a.c_customer_sk
          AND sr3.sr_returned_date_sk = a.d_date_sk
    ) AS latest_return_amt,
    a.distinct_customers
FROM aggregated a
JOIN intersect_stores i ON i.s_store_id = a.s_store_id
LEFT JOIN except_stores e ON e.s_store_id = a.s_store_id
WHERE e.s_store_id IS NULL
ORDER BY a.total_sales DESC, a.d_year, a.d_month_seq
LIMIT 100
