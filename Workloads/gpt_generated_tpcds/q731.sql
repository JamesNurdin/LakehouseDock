WITH sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        i.i_category
),
returns AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2022-01-01' AND d.d_date <= DATE '2022-12-31'
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        i.i_category
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.d_year,
    s.d_month_seq,
    s.cd_gender,
    s.i_category,
    s.total_net_paid,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    s.total_net_paid - COALESCE(r.total_return_amt, 0) AS net_sales_after_returns,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    CASE WHEN s.total_quantity > 0 THEN COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_quantity ELSE 0 END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.s_store_id = r.s_store_id
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.cd_gender = r.cd_gender
    AND s.i_category = r.i_category
ORDER BY net_sales_after_returns DESC
LIMIT 100
