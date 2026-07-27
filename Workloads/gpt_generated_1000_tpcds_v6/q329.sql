WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_division_name,
        d.d_quarter_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        MIN(ss.ss_sold_time_sk) AS min_time_sk
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_credit_rating, '^(Good|Low Risk)$')
      AND d.d_quarter_name = '1904Q2'
    GROUP BY s.s_store_sk, s.s_division_name, d.d_quarter_name
)

SELECT
    sb.s_division_name,
    sb.total_profit,
    sb.sales_cnt,
    CONCAT(s.s_manager, ' - ', sb.s_division_name) AS manager_division,
    (SELECT AVG(total_profit) FROM sales_by_store) AS avg_div_profit
FROM sales_by_store sb
JOIN store s
    ON sb.s_store_sk = s.s_store_sk
WHERE s.s_manager LIKE '% %'
  AND regexp_extract(s.s_manager, '(\\w+) (\\w+)', 1) = 'Joe'
  AND EXISTS (
        SELECT 1
        FROM time_dim t
        WHERE t.t_time_sk = sb.min_time_sk
          AND t.t_shift = 'AM'
    )
ORDER BY sb.total_profit DESC
LIMIT 10
