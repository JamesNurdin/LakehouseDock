WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk, ss.ss_sold_date_sk
),
returns_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt,
        COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_returned
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_id,
    p.p_promo_name,
    d_sales.d_year AS sales_year,
    d_sales.d_quarter_name AS sales_quarter,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.total_discount, 0) AS total_discount,
    COALESCE(sa.total_profit, 0) AS total_profit,
    COALESCE(ra.total_return_amt, 0) AS total_return_amount,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    CASE
        WHEN COALESCE(sa.total_sales, 0) = 0 THEN 0
        ELSE COALESCE(ra.total_return_amt, 0) / COALESCE(sa.total_sales, 0)
    END AS return_to_sales_ratio,
    (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amt, 0)) AS net_sales_minus_returns,
    d_store_closed.d_year AS store_closed_year,
    d_return.d_year AS return_year
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN returns_agg ra
    ON sa.ss_sold_date_sk = ra.wr_returned_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_return
    ON ra.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sales.d_year = 2022
ORDER BY net_sales_minus_returns DESC
LIMIT 100
