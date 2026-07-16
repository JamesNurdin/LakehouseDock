WITH store_agg AS (
 SELECT d.d_year AS year,
        st.s_state AS state,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_quantity) AS qty
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store st ON ss.ss_store_sk = st.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, st.s_state, i.i_category
),
web_agg AS (
 SELECT d.d_year AS year,
        ws_site.web_state AS state,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_quantity) AS qty
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, ws_site.web_state, i.i_category
),
catalog_agg AS (
 SELECT d.d_year AS year,
        cc.cc_state AS state,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_quantity) AS qty
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, cc.cc_state, i.i_category
),
combined AS (
 SELECT year, state, category, profit, net_paid, qty FROM store_agg
 UNION ALL
 SELECT year, state, category, profit, net_paid, qty FROM web_agg
 UNION ALL
 SELECT year, state, category, profit, net_paid, qty FROM catalog_agg
),
aggregated AS (
 SELECT year,
        state,
        category,
        SUM(profit) AS total_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(qty) AS total_qty
 FROM combined
 GROUP BY year, state, category
),
ranked AS (
 SELECT year,
        state,
        category,
        total_profit,
        total_net_paid,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY year, state ORDER BY total_profit DESC) AS rank,
        CASE
            WHEN total_profit > 1000000 THEN 'High'
            WHEN total_profit > 500000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_class,
        total_profit / NULLIF(total_qty, 0) AS avg_profit_per_item,
        SUM(total_profit) OVER (PARTITION BY year, state ORDER BY total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
 FROM aggregated
 WHERE total_qty > 0
)
SELECT r.year,
       r.state,
       r.category,
       r.total_profit,
       r.total_net_paid,
       r.total_qty,
       r.rank,
       r.profit_class,
       r.avg_profit_per_item,
       r.cumulative_profit,
       r.total_profit / NULLIF((SELECT SUM(a2.total_profit)
                                 FROM aggregated a2
                                 WHERE a2.year = r.year
                                   AND a2.category = r.category), 0) AS profit_share_year_category
FROM ranked r
WHERE r.rank <= 5
ORDER BY r.year, r.state, r.rank
