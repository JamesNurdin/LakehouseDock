WITH sales_cte AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_item_desc,
        i.i_category,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        td.t_hour,
        td.t_am_pm,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS item_code
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE regexp_like(i.i_item_desc, '[A-Za-z]{3}\\d{2}')
      AND i.i_item_desc LIKE '%Gold%'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_store_sk = s.s_store_sk
            AND sr.sr_return_quantity > 5
      )
)
SELECT
    s_store_name,
    i_category,
    MIN(item_code) AS sample_item_code,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(ss_net_profit) > (SELECT AVG(ss_net_profit) FROM sales_cte) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_level,
    CONCAT(s_store_name, ' - ', i_category) AS store_category_label
FROM sales_cte
GROUP BY GROUPING SETS (
    (s_store_name, i_category),
    (s_store_name),
    (i_category),
    ()
)
ORDER BY total_profit DESC NULLS LAST, s_store_name
LIMIT 100
