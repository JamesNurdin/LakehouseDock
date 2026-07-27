WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        cs.cs_bill_customer_sk AS cs_customer_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_bill_customer_sk AS ws_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ext_ship_cost,
        ws.ws_net_profit AS ws_net_profit
    FROM
        promotion p
        JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
        JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        p.p_channel_tv = 'N'
        AND p.p_purpose = 'Unknown'
        AND cs.cs_ext_discount_amt > 1000
        AND cs.cs_ship_hdemo_sk IN (4052, 5455)
        AND ws.ws_ext_ship_cost > 200
        AND ws.ws_ship_customer_sk BETWEEN 1000000 AND 12000000
),
agg AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        cs_customer_sk,
        ws_customer_sk,
        SUM(cs_net_profit) AS catalog_profit,
        SUM(ws_net_profit) AS web_profit,
        SUM(cs_net_profit + ws_net_profit) AS total_profit
    FROM promo_sales
    GROUP BY GROUPING SETS (
        (p_promo_sk, p_promo_name, cs_customer_sk, ws_customer_sk),
        (p_promo_sk, p_promo_name)
    )
)
SELECT
    p_promo_sk,
    p_promo_name,
    cs_customer_sk,
    ws_customer_sk,
    catalog_profit,
    web_profit,
    total_profit,
    RANK() OVER (PARTITION BY p_promo_sk ORDER BY total_profit DESC) AS profit_rank,
    (SELECT AVG(total_profit) FROM agg) AS avg_total_profit_all_promos
FROM agg
ORDER BY total_profit DESC
LIMIT 100
