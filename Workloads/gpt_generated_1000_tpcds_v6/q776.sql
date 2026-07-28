WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)cool')
      AND ca.ca_city LIKE 'A%'
      AND d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
)
SELECT
    CONCAT(sa.s_store_name, ' ', CAST(sa.d_year AS VARCHAR)) AS store_year,
    sa.s_store_name,
    sa.d_year,
    sa.total_net_profit,
    sa.total_net_paid,
    sa.sales_cnt,
    sa.total_net_profit / NULLIF(sa.sales_cnt, 0) AS avg_profit_per_sale,
    (
        SELECT AVG(sr.sr_return_amt)
        FROM store_returns sr
        WHERE sr.sr_store_sk = sa.s_store_sk
    ) AS avg_return_amount,
    (
        SELECT COUNT(*)
        FROM store_returns sr
        JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
        WHERE sr.sr_store_sk = sa.s_store_sk
          AND d2.d_year = sa.d_year
    ) AS return_cnt_this_year
FROM sales_agg sa
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE sr.sr_store_sk = sa.s_store_sk
      AND d2.d_year = sa.d_year
)
ORDER BY sa.total_net_profit DESC
LIMIT 10
