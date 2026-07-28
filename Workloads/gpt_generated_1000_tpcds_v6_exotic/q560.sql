WITH cs AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id,
        p.p_promo_id,
        p.p_promo_name,
        cs.cs_net_profit,
        cs.cs_order_number,
        regexp_extract(p.p_promo_name, '(\\w+) Promo', 1) AS promo_type,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_customer_id, '^AAAAAAA[PH]HEGGAA$')
      AND p.p_promo_name LIKE '%Discount%'
),
ws AS (
    SELECT
        d.d_year AS year,
        c.c_customer_id,
        p.p_promo_id,
        p.p_promo_name,
        ws.ws_net_profit,
        ws.ws_order_number,
        regexp_extract(p.p_promo_name, '(\\w+) Promo', 1) AS promo_type,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_customer_id, '^AAAAAAA[PH]HEGGAA$')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    t.year,
    t.profit_category,
    t.promo_type,
    COUNT(DISTINCT t.order_number) AS distinct_orders,
    SUM(t.net_profit) AS total_profit,
    RANK() OVER (PARTITION BY t.year ORDER BY SUM(t.net_profit) DESC) AS profit_rank
FROM (
    SELECT
        year,
        profit_category,
        promo_type,
        cs_order_number AS order_number,
        cs_net_profit AS net_profit
    FROM cs
    UNION ALL
    SELECT
        year,
        profit_category,
        promo_type,
        ws_order_number AS order_number,
        ws_net_profit AS net_profit
    FROM ws
) t
GROUP BY t.year, t.profit_category, t.promo_type
ORDER BY total_profit DESC
LIMIT 100
