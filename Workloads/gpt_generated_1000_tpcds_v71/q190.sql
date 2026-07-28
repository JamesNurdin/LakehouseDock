WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_store_name LIKE 'A%'
      AND d.d_year = 2001
      AND regexp_like(i.i_item_desc, '\\d{3}')
      AND substring(i.i_product_name, 1, 5) = 'SMALL'
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = ss.ss_item_sk
      )
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
)
SELECT
    concat(s_store_name, ' - ', s_state) AS store_full_name,
    s_state,
    total_profit,
    sales_cnt,
    row_number() OVER (PARTITION BY s_state ORDER BY total_profit DESC) AS state_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
