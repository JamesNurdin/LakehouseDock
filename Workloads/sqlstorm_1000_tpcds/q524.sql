WITH store_agg AS (
    SELECT
        d.d_year,
        s.s_state AS region,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_net_paid) AS total_paid,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, s.s_state, i.i_category
),
catalog_agg AS (
    SELECT
        d.d_year,
        cc.cc_state AS region,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, cc.cc_state, i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        wsite.web_state AS region,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_net_paid) AS total_paid,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, wsite.web_state, i.i_category
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    c.d_year,
    c.region,
    c.channel,
    c.i_category,
    c.total_profit,
    c.total_paid,
    c.distinct_customers,
    RANK() OVER (PARTITION BY c.channel, c.d_year, c.region ORDER BY c.total_profit DESC) AS profit_rank,
    c.total_profit / SUM(c.total_profit) OVER (PARTITION BY c.channel, c.d_year) AS profit_share,
    SUM(c.total_profit) OVER (PARTITION BY c.channel, c.region ORDER BY c.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
FROM combined c
ORDER BY c.channel, c.d_year, c.region, profit_rank
LIMIT 200
