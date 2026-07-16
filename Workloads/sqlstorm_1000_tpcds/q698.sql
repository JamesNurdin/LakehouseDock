WITH sales AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS order_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq, i.i_category
),
final AS (
    SELECT
        s.s_store_id,
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.total_sales,
        COALESCE(r.total_loss, 0) AS total_loss,
        s.total_profit - COALESCE(r.total_loss, 0) AS net_profit,
        s.order_count,
        COALESCE(r.return_count, 0) AS return_count
    FROM sales s
    LEFT JOIN returns_agg r
        ON s.s_store_id = r.s_store_id
        AND s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.i_category = r.i_category
)
SELECT
    f.s_store_id,
    f.d_year,
    f.d_month_seq,
    f.i_category,
    f.total_sales,
    f.total_loss,
    f.net_profit,
    f.order_count,
    f.return_count,
    rank() OVER (PARTITION BY f.s_store_id, f.d_year ORDER BY f.total_sales DESC) AS category_rank
FROM final f
ORDER BY f.total_sales DESC
LIMIT 100
