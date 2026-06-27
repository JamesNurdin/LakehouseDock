WITH store_sales_data AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        ss.ss_quantity,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
),
catalog_sales_data AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        cs.cs_quantity,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
),
web_sales_data AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
),
combined_sales AS (
    SELECT p_promo_sk, p_promo_name, d_year, d_month_seq, ss_quantity AS quantity, ss_net_profit AS net_profit, 'store'   AS channel FROM store_sales_data
    UNION ALL
    SELECT p_promo_sk, p_promo_name, d_year, d_month_seq, cs_quantity AS quantity, cs_net_profit AS net_profit, 'catalog' AS channel FROM catalog_sales_data
    UNION ALL
    SELECT p_promo_sk, p_promo_name, d_year, d_month_seq, ws_quantity AS quantity, ws_net_profit AS net_profit, 'web'     AS channel FROM web_sales_data
)
SELECT
    p_promo_sk,
    p_promo_name,
    d_year,
    d_month_seq,
    channel,
    SUM(quantity)   AS total_quantity,
    SUM(net_profit) AS total_net_profit
FROM combined_sales
GROUP BY p_promo_sk, p_promo_name, d_year, d_month_seq, channel
ORDER BY total_net_profit DESC
LIMIT 20
