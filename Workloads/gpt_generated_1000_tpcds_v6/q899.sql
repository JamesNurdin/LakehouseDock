WITH sales_base AS (
    SELECT
        ss.ss_store_sk,
        d.d_date,
        d.d_year,
        p.p_promo_id,
        p.p_discount_active,
        ss.ss_net_paid               AS ss_net_paid,
        cs.cs_net_paid               AS cs_net_paid,
        ws.ws_net_paid               AS ws_net_paid,
        ss.ss_ext_tax                AS ss_ext_tax,
        cp.cp_department             AS cp_department
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND ss.ss_ext_tax > 5
)
SELECT
    ss_store_sk,
    d_date,
    d_year,
    SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) + COALESCE(ws_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) + COALESCE(ws_net_paid, 0)) /
        (SELECT AVG(ss_net_paid) FROM store_sales) AS relative_to_store_avg,
    CASE
        WHEN SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) + COALESCE(ws_net_paid, 0)) > 200000 THEN 'High'
        WHEN SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) + COALESCE(ws_net_paid, 0)) > 100000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (
        PARTITION BY d_year
        ORDER BY SUM(COALESCE(ss_net_paid, 0) + COALESCE(cs_net_paid, 0) + COALESCE(ws_net_paid, 0)) DESC
    ) AS revenue_rank
FROM sales_base
GROUP BY ss_store_sk, d_date, d_year
ORDER BY total_net_paid DESC
LIMIT 100
