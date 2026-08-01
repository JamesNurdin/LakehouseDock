WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(DISTINCT ss.ss_ext_tax) AS sum_distinct_tax
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY ss.ss_item_sk, d.d_year
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_start.d_year AS promo_start_year,
    sa.total_net_paid,
    sa.distinct_tickets,
    sa.sum_distinct_tax,
    COUNT(DISTINCT r.r_reason_id) AS distinct_reason_cnt,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sa.total_net_paid DESC) AS rn,
    color_part
FROM sales_agg sa
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN promotion p ON i.i_item_sk = p.p_item_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store_sales ss2 ON ss2.ss_item_sk = i.i_item_sk
JOIN household_demographics hd ON ss2.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
FULL OUTER JOIN catalog_page cp ON cp.cp_start_date_sk = d_start.d_date_sk
FULL OUTER JOIN catalog_page cp_full ON cp_full.cp_end_date_sk = d_end.d_date_sk
JOIN (
    SELECT * FROM web_returns TABLESAMPLE BERNOULLI (10)
) wr ON wr.wr_item_sk = i.i_item_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws ON ws.web_open_date_sk = d_start.d_date_sk
CROSS JOIN UNNEST(split(i.i_color, ',')) AS u(color_part)
WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
      AND p2.p_discount_active = 'Y'
)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_start.d_year,
    sa.total_net_paid,
    sa.distinct_tickets,
    sa.sum_distinct_tax,
    color_part
ORDER BY sa.total_net_paid DESC, i.i_item_id
LIMIT 100
