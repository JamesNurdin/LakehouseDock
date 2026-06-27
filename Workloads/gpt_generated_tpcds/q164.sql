WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category
)
SELECT
    COALESCE(s.s_store_name, r.s_store_name) AS store_name,
    COALESCE(s.d_year, r.d_year) AS year,
    COALESCE(s.d_month_seq, r.d_month_seq) AS month_seq,
    COALESCE(s.i_category, r.i_category) AS category,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
  ON s.s_store_sk = r.s_store_sk
  AND s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
  AND s.i_category = r.i_category
ORDER BY
    store_name,
    year,
    month_seq,
    category
