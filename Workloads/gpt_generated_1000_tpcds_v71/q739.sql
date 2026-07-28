WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS ticket_cnt,
        AVG(ss.ss_ext_tax) AS avg_tax
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND d.d_current_year = 'Y'
      AND ss.ss_ext_tax > 10.00
    GROUP BY d.d_year, d.d_month_seq, d.d_date_sk
)
SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.total_profit,
    sa.ticket_cnt,
    w.wp_type,
    w.wp_char_count,
    ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
    CASE WHEN w.wp_char_count IS NULL THEN 'NoPage' ELSE 'HasPage' END AS page_presence
FROM sales_agg sa
LEFT JOIN web_page w
  ON w.wp_creation_date_sk = sa.d_date_sk
WHERE (w.wp_char_count > 2000 OR w.wp_char_count IS NULL)
  AND (w.wp_type = 'FAQ' OR w.wp_type IS NULL)
