WITH store_profit AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_moy AS month,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_sk, p.p_promo_name, d.d_year, d.d_moy
),
catalog_profit AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_moy AS month,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_sk, p.p_promo_name, d.d_year, d.d_moy
),
web_profit AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_moy AS month,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_sk, p.p_promo_name, d.d_year, d.d_moy
),
combined AS (
    SELECT p_promo_sk, p_promo_name, d_year, month, net_profit FROM store_profit
    UNION ALL
    SELECT p_promo_sk, p_promo_name, d_year, month, net_profit FROM catalog_profit
    UNION ALL
    SELECT p_promo_sk, p_promo_name, d_year, month, net_profit FROM web_profit
)
SELECT
    p_promo_name,
    d_year,
    month,
    SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY p_promo_name, d_year, month
ORDER BY total_net_profit DESC
LIMIT 20
