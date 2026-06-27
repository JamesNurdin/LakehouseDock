WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        sum(ss.ss_net_profit) AS sales_net_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        sum(sr.sr_net_loss) AS returns_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year, d.d_month_seq
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.d_year,
    s.d_month_seq,
    s.sales_net_profit - coalesce(r.returns_net_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_id = r.s_store_id
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year DESC, s.d_month_seq DESC, net_profit_after_returns DESC
