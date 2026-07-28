/*
  Goal: Analyze store sales performance by store, year, and promotion for customers born in July, limited to California stores, active promotions, high‑quantity sales, and customers who have an 'article' web page. The query aggregates net paid amount, average profit, and sales count, and uses an EXISTS subquery to ensure the promotion started on the earliest sales date in 2002.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        p.p_promo_name,
        SUM(ss.ss_net_paid)        AS total_net_paid,
        AVG(ss.ss_net_profit)      AS avg_net_profit,
        COUNT(*)                   AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND c.c_birth_month = 7
      AND cd.cd_credit_rating = 'Excellent'
      AND ss.ss_quantity > 5
      AND wp.wp_type = 'article'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_id = p.p_promo_id
            AND p2.p_start_date_sk = (
                SELECT MIN(d2.d_date_sk)
                FROM date_dim d2
                WHERE d2.d_year = 2002
            )
      )
    GROUP BY s.s_store_name, d.d_year, p.p_promo_name
)
SELECT *
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
