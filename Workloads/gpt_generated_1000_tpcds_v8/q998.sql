/*
 * Goal: Compare total store return amounts with total web sales amounts per year (year = 2002) for male customers with relatively high purchase estimates, while demonstrating advanced Trino features such as TABLESAMPLE, anti‑joins, FULL OUTER JOIN, UNION, LATERAL subqueries and IN‑subqueries.
 */
WITH sampled_returns AS (
    -- Sample 10% of the store_returns table to reduce scan size
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_quantity > 1
),
filtered_store AS (
    -- Keep stores in CA or TX with enough employees and whose keys appear in store_returns
    SELECT *
    FROM store
    WHERE s_state IN ('CA', 'TX')
      AND s_number_employees > 50
      AND s_store_sk IN (SELECT sr_store_sk FROM store_returns WHERE sr_return_quantity > 5)
),
joined_returns AS (
    -- Join sampled returns to the dimensional tables and apply several filters
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        r.r_reason_desc
    FROM sampled_returns sr
    JOIN date_dim d      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r       ON sr.sr_reason_sk = r.r_reason_sk
    JOIN filtered_store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 3000
      AND r.r_reason_id = 'AAAAAAAAEBAAAAAA'
      -- anti‑join: exclude returns that have a matching web sale on the same date & customer
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_sold_date_sk = sr.sr_returned_date_sk
            AND ws.ws_bill_customer_sk = sr.sr_customer_sk
      )
),
web_agg AS (
    -- Aggregate web sales with the same filter set
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        d.d_year,
        t.t_hour,
        wp.wp_link_count,
        wp.wp_autogen_flag,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp     ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 3000
      AND wp.wp_autogen_flag = 'N'
),
full_store_date AS (
    -- FULL OUTER JOIN between stores and the date dimension on the store‑closed date
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year
    FROM filtered_store s
    FULL OUTER JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
),
union_agg AS (
    -- UNION of the two yearly aggregates (distinct by default)
    SELECT
        'return' AS source,
        d_year,
        SUM(sr_return_amt)            AS total_amount,
        COUNT(*)                      AS cnt,
        MIN(sr_return_amt)            AS min_amt,
        MAX(sr_return_amt)            AS max_amt
    FROM joined_returns
    GROUP BY d_year
    UNION
    SELECT
        'web' AS source,
        d_year,
        SUM(ws_ext_sales_price)       AS total_amount,
        COUNT(*)                      AS cnt,
        MIN(ws_ext_sales_price)       AS min_amt,
        MAX(ws_ext_sales_price)       AS max_amt
    FROM web_agg
    GROUP BY d_year
)
SELECT
    ua.source,
    ua.d_year,
    ua.total_amount,
    ua.cnt,
    ua.min_amt,
    ua.max_amt,
    fsd.s_store_name,
    fsd.s_state,
    lt.avg_amount_per_year
FROM union_agg ua
LEFT JOIN full_store_date fsd
    ON ua.d_year = fsd.d_year
CROSS JOIN LATERAL (
    SELECT AVG(total_amount) AS avg_amount_per_year
    FROM union_agg ua2
    WHERE ua2.d_year = ua.d_year
) lt
WHERE ua.total_amount > 1000
  AND ua.cnt >= 5
ORDER BY ua.total_amount DESC
LIMIT 100
