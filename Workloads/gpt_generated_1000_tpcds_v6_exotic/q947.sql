WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
            ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
        END AS profit_margin
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_fy_year BETWEEN 1905 AND 1910
      AND c.c_birth_month = 5
      AND p.p_channel_email = 'Y'
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, p.p_promo_id
)
SELECT
    sa.s_store_name,
    sa.d_year,
    SUM(sa.total_sales) AS year_sales,
    AVG(sa.profit_margin) AS avg_profit_margin,
    COUNT(DISTINCT sa.p_promo_id) AS promo_count,
    (SELECT MIN(p2.p_cost)
       FROM promotion p2
       WHERE p2.p_promo_id = sa.p_promo_id) AS min_promo_cost
FROM sales_agg sa
WHERE sa.total_profit > 1000
  AND EXISTS (
        SELECT 1
        FROM promotion p3
        WHERE p3.p_promo_id = sa.p_promo_id
          AND p3.p_purpose = 'Unknown'
      )
  AND sa.p_promo_id IN (
        SELECT DISTINCT p4.p_promo_id
        FROM promotion p4
        WHERE p4.p_channel_catalog = 'N'
      )
GROUP BY sa.s_store_name, sa.d_year, sa.p_promo_id
HAVING AVG(sa.profit_margin) > 0.05
ORDER BY year_sales DESC, sa.s_store_name
LIMIT 100
