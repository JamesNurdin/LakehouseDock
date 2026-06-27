WITH sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender,
        SUM(ss.ss_quantity) AS total_sales_qty,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender
),
returns AS (
    SELECT
        sr.sr_store_sk AS s_store_sk,
        d.d_year AS return_year,
        d.d_month_seq AS return_month_seq,
        i.i_category,
        cd.cd_gender,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender
)
SELECT
    s.s_store_name,
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.cd_gender,
    s.total_sales_qty,
    s.total_sales_amount,
    s.total_net_profit,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN s.total_sales_qty > 0 THEN COALESCE(r.total_return_qty, 0) / s.total_sales_qty
        ELSE 0
    END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.s_store_sk = r.s_store_sk
    AND s.d_year = r.return_year
    AND s.d_month_seq = r.return_month_seq
    AND s.i_category = r.i_category
    AND s.cd_gender = r.cd_gender
ORDER BY
    s.s_store_name,
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.cd_gender
