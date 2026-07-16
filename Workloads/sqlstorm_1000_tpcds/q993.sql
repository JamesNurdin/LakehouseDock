WITH
catalog_aggr AS (
    SELECT
        d.d_year AS sales_year,
        cc.cc_state AS sales_state,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(*) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, cc.cc_state, i.i_category
),
store_aggr AS (
    SELECT
        d.d_year AS sales_year,
        s.s_state AS sales_state,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(*) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, s.s_state, i.i_category
),
web_aggr AS (
    SELECT
        d.d_year AS sales_year,
        w.web_state AS sales_state,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(*) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, w.web_state, i.i_category
),
combined AS (
    SELECT * FROM catalog_aggr
    UNION ALL
    SELECT * FROM store_aggr
    UNION ALL
    SELECT * FROM web_aggr
),
final AS (
    SELECT
        sales_year,
        sales_state,
        category,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(orders) AS total_orders
    FROM combined
    GROUP BY sales_year, sales_state, category
)
SELECT
    sales_year,
    sales_state,
    category,
    total_net_profit,
    total_net_paid,
    total_orders,
    rank_by_profit
FROM (
    SELECT
        sales_year,
        sales_state,
        category,
        total_net_profit,
        total_net_paid,
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS rank_by_profit
    FROM final
) t
WHERE rank_by_profit <= 10
ORDER BY sales_year, rank_by_profit
