WITH avg_price AS (
        SELECT avg(i_current_price) AS avg_price
        FROM tpcds.item
    ),
    store_sales_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(ss.ss_net_paid) AS total_amount,
            CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
        FROM tpcds.store_sales ss
        JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
        WHERE i.i_current_price > (SELECT avg_price FROM avg_price)
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, i.i_category
    ),
    web_returns_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(wr.wr_return_amt) AS total_amount,
            CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Recovered' END AS profit_flag
        FROM tpcds.web_returns wr
        JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
        LEFT JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE i.i_current_price > (SELECT avg_price FROM avg_price)
          AND r.r_reason_desc LIKE '%warranty%'
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year, i.i_category
    )
SELECT
    sa.year,
    sa.category,
    sa.total_amount,
    sa.profit_flag
FROM store_sales_agg sa
UNION ALL
SELECT
    wa.year,
    wa.category,
    wa.total_amount,
    wa.profit_flag
FROM web_returns_agg wa
ORDER BY year, category
LIMIT 100
