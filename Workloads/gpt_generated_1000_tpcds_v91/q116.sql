WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
      AND s.s_tax_percentage > (SELECT AVG(s_tax_percentage) FROM store)
    GROUP BY GROUPING SETS (
        (s.s_store_name, i.i_item_id, d.d_year),
        (s.s_store_name, i.i_item_id),
        (s.s_store_name),
        ()
    )
),
returns_agg AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS transaction_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
      AND s.s_tax_percentage > (SELECT AVG(s_tax_percentage) FROM store)
    GROUP BY GROUPING SETS (
        (s.s_store_name, i.i_item_id, d.d_year),
        (s.s_store_name, i.i_item_id),
        (s.s_store_name),
        ()
    )
),
combined AS (
    SELECT
        store_name,
        item_id,
        year,
        total_sales,
        total_profit,
        transaction_cnt
    FROM sales_agg
    UNION ALL
    SELECT
        store_name,
        item_id,
        year,
        -total_return_amount AS total_sales,
        -total_net_loss AS total_profit,
        transaction_cnt
    FROM returns_agg
)
SELECT
    store_name,
    item_id,
    year,
    total_sales,
    total_profit,
    transaction_cnt,
    ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY store_name) AS store_total_sales
FROM combined
WHERE total_sales IS NOT NULL
ORDER BY store_name, total_sales DESC
LIMIT 100
