WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        p.p_promo_id,
        p.p_promo_name,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        REGEXP_EXTRACT(c.c_email_address, '@([^\\.]+)\\.', 1) AS email_domain
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(p.p_channel_details, 'rarely')
      AND c.c_email_address LIKE '%@gmail.com'
      AND t.t_meal_time LIKE '%Dinner%'
      AND d.d_year = 1902
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_id,
        p.p_promo_name,
        d.d_year,
        c.c_email_address
)
SELECT
    s.c_customer_id,
    s.full_name,
    s.p_promo_name,
    s.d_year,
    s.total_net_paid,
    s.total_net_profit,
    CASE WHEN s.total_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    s.email_domain,
    SUBSTRING(s.p_promo_name FROM 1 FOR 10) AS short_promo_name,
    ROW_NUMBER() OVER (PARTITION BY s.p_promo_id ORDER BY s.total_net_profit DESC) AS promo_profit_rank,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN promotion p2 ON cs2.cs_promo_sk = p2.p_promo_sk
        WHERE p2.p_promo_id = s.p_promo_id
    ) AS avg_promo_profit,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        WHERE c2.c_customer_id = s.c_customer_id
          AND dr.d_year = s.d_year
          AND sr.sr_net_loss > 0
    ) THEN 'Yes' ELSE 'No' END AS has_store_return_loss
FROM sales_agg s
ORDER BY s.total_net_profit DESC
LIMIT 100
