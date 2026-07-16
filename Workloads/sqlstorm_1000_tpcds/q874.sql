WITH base AS (
    SELECT d.d_year,
           ca.ca_state,
           'store' AS channel,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_sales_price AS total_sales,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN (SELECT max(d_year) - 2 FROM date_dim) AND (SELECT max(d_year) FROM date_dim)
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           'web' AS channel,
           ws.ws_net_profit,
           ws.ws_ext_sales_price,
           ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN (SELECT max(d_year) - 2 FROM date_dim) AND (SELECT max(d_year) FROM date_dim)
    UNION ALL
    SELECT d.d_year,
           ca.ca_state,
           'catalog' AS channel,
           cs.cs_net_profit,
           cs.cs_ext_sales_price,
           cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN (SELECT max(d_year) - 2 FROM date_dim) AND (SELECT max(d_year) FROM date_dim)
), agg AS (
    SELECT d_year,
           ca_state,
           channel,
           SUM(net_profit) AS net_profit,
           SUM(total_sales) AS total_sales,
           SUM(quantity) AS total_quantity,
           SUM(net_profit) / NULLIF(SUM(total_sales), 0) AS profit_margin
    FROM base
    GROUP BY d_year, ca_state, channel
)
SELECT
    a.d_year,
    a.ca_state,
    a.channel,
    a.net_profit,
    a.total_sales,
    a.total_quantity,
    a.profit_margin,
    a.net_profit / NULLIF(state_totals.total_state_profit, 0) AS channel_profit_pct,
    state_totals.total_state_profit,
    LAG(state_totals.total_state_profit) OVER (PARTITION BY a.ca_state ORDER BY a.d_year) AS prev_state_profit,
    (state_totals.total_state_profit - LAG(state_totals.total_state_profit) OVER (PARTITION BY a.ca_state ORDER BY a.d_year)) / NULLIF(LAG(state_totals.total_state_profit) OVER (PARTITION BY a.ca_state ORDER BY a.d_year), 0) AS profit_yoy_change,
    CASE WHEN (state_totals.total_state_profit - LAG(state_totals.total_state_profit) OVER (PARTITION BY a.ca_state ORDER BY a.d_year)) / NULLIF(LAG(state_totals.total_state_profit) OVER (PARTITION BY a.ca_state ORDER BY a.d_year), 0) > 0.2 THEN 'High Growth' ELSE 'Normal' END AS growth_flag,
    state_rankings.state_rank
FROM agg a
JOIN (
    SELECT d_year,
           ca_state,
           SUM(net_profit) AS total_state_profit
    FROM agg
    GROUP BY d_year, ca_state
) state_totals
    ON a.d_year = state_totals.d_year AND a.ca_state = state_totals.ca_state
JOIN (
    SELECT d_year,
           ca_state,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(net_profit) DESC) AS state_rank
    FROM agg
    GROUP BY d_year, ca_state
) state_rankings
    ON a.d_year = state_rankings.d_year AND a.ca_state = state_rankings.ca_state
WHERE state_rankings.state_rank <= 5
ORDER BY a.d_year, state_rankings.state_rank, a.channel
