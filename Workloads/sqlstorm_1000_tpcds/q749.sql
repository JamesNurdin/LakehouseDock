WITH
store_sales_pre AS (
    SELECT
        ss.ss_sold_date_sk AS sale_date_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        s.s_state AS state,
        'store' AS channel,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
),
catalog_sales_pre AS (
    SELECT
        cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cc.cc_state AS state,
        'catalog' AS channel,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
),
web_sales_pre AS (
    SELECT
        ws.ws_sold_date_sk AS sale_date_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        w.web_state AS state,
        'web' AS channel,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
),
union_sales AS (
    SELECT * FROM store_sales_pre
    UNION ALL
    SELECT * FROM catalog_sales_pre
    UNION ALL
    SELECT * FROM web_sales_pre
),
sales_with_date AS (
    SELECT
        u.*,
        d.d_year,
        d.d_moy AS month
    FROM union_sales u
    JOIN date_dim d ON u.sale_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
agg AS (
    SELECT
        d_year,
        month,
        state,
        channel,
        sum(net_paid) AS total_net_paid,
        sum(net_profit) AS total_net_profit,
        sum(quantity) AS total_quantity,
        count(*) AS txn_count,
        avg(net_paid) AS avg_net_paid
    FROM sales_with_date
    GROUP BY d_year, month, state, channel
)
SELECT
    *,
    rank() OVER (PARTITION BY d_year, month ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, month, profit_rank
