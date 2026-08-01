WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),

promo_sales AS (
    SELECT
        ca.ca_state,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        'Promoted' AS promo_flag
    FROM sampled_ws ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
      AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY ca.ca_state, d.d_year
),

nonpromo_sales AS (
    SELECT
        ca.ca_state,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        'NonPromoted' AS promo_flag
    FROM sampled_ws ws
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_promo_sk IS NULL
      AND d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY ca.ca_state, d.d_year
)

SELECT
    ca_state,
    d_year,
    promo_flag,
    total_profit,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY promo_flag ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT * FROM promo_sales
    UNION ALL
    SELECT * FROM nonpromo_sales
) combined
ORDER BY promo_flag, total_profit DESC
LIMIT 100
