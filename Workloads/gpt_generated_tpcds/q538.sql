WITH aggregated AS (
    SELECT
        t.s_name               AS store_name,
        t.year,
        t.month,
        t.category,
        sum(t.total_sales_net_paid)      AS total_sales_net_paid,
        sum(t.total_discount_amount)     AS total_discount_amount,
        sum(t.total_sales_profit)        AS total_sales_profit,
        sum(t.total_return_loss)         AS total_return_loss,
        sum(t.total_sales_profit) - sum(t.total_return_loss) AS net_profit_after_returns
    FROM (
        -- Sales rows (positive revenue)
        SELECT
            s.s_store_name        AS s_name,
            ds.d_year             AS year,
            ds.d_moy              AS month,
            i.i_category          AS category,
            ss.ss_net_paid        AS total_sales_net_paid,
            ss.ss_ext_discount_amt AS total_discount_amount,
            ss.ss_net_profit      AS total_sales_profit,
            CAST(0.0 AS decimal(7,2)) AS total_return_loss
        FROM store_sales ss
        JOIN store s      ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim ds  ON ss.ss_sold_date_sk = ds.d_date_sk
        JOIN item i       ON ss.ss_item_sk = i.i_item_sk
        WHERE ds.d_year = 2002

        UNION ALL

        -- Return rows (negative impact)
        SELECT
            s.s_store_name        AS s_name,
            ds.d_year             AS year,
            ds.d_moy              AS month,
            i.i_category          AS category,
            CAST(0.0 AS decimal(7,2)) AS total_sales_net_paid,
            CAST(0.0 AS decimal(7,2)) AS total_discount_amount,
            CAST(0.0 AS decimal(7,2)) AS total_sales_profit,
            sr.sr_net_loss        AS total_return_loss
        FROM store_returns sr
        JOIN store s      ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim ds  ON sr.sr_returned_date_sk = ds.d_date_sk
        JOIN item i       ON sr.sr_item_sk = i.i_item_sk
        WHERE ds.d_year = 2002
    ) t
    GROUP BY t.s_name, t.year, t.month, t.category
)
SELECT
    store_name,
    year,
    month,
    category,
    total_sales_net_paid,
    total_discount_amount,
    total_sales_profit,
    total_return_loss,
    net_profit_after_returns,
    rank() OVER (PARTITION BY store_name, year, month ORDER BY net_profit_after_returns DESC) AS category_rank
FROM aggregated
ORDER BY store_name, year, month, category_rank
