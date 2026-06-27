SELECT
    combined.p_promo_name,
    combined.d_year,
    combined.d_month_seq,
    combined.channel,
    sum(combined.net_profit) AS total_net_profit
FROM (
    SELECT
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        ss.ss_net_profit AS net_profit,
        'Store' AS channel
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998

    UNION ALL

    SELECT
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        cs.cs_net_profit AS net_profit,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998

    UNION ALL

    SELECT
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        ws.ws_net_profit AS net_profit,
        'Web' AS channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
) AS combined
GROUP BY
    combined.p_promo_name,
    combined.d_year,
    combined.d_month_seq,
    combined.channel
ORDER BY
    combined.p_promo_name,
    combined.d_year,
    combined.d_month_seq,
    combined.channel
