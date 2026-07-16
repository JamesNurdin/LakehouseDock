WITH sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS channel_sk,
           cs_promo_sk,
           cs_quantity AS quantity,
           cs_ext_discount_amt AS discount_amt,
           cs_net_profit AS net_profit,
           'catalog' AS channel_type
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_store_sk,
           ss_promo_sk,
           ss_quantity,
           ss_ext_discount_amt,
           ss_net_profit,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_site_sk,
           ws_promo_sk,
           ws_quantity,
           ws_ext_discount_amt,
           ws_net_profit,
           'web'
    FROM web_sales
),
channel_dim AS (
    SELECT cc.cc_call_center_sk AS channel_sk, 'catalog' AS channel_type, cc.cc_state AS state
    FROM call_center cc
    UNION ALL
    SELECT st.s_store_sk, 'store', st.s_state
    FROM store st
    UNION ALL
    SELECT ws.web_site_sk, 'web', ws.web_state
    FROM web_site ws
),
sales_with_dim AS (
    SELECT s.date_sk,
           s.item_sk,
           s.channel_type,
           cd.state,
           s.quantity,
           s.discount_amt,
           s.net_profit
    FROM sales s
    LEFT JOIN channel_dim cd
      ON s.channel_sk = cd.channel_sk
     AND s.channel_type = cd.channel_type
),
aggregated AS (
    SELECT d.d_year,
           i.i_category,
           swd.channel_type,
           swd.state,
           SUM(swd.quantity) AS total_quantity,
           SUM(swd.net_profit) AS total_net_profit,
           SUM(swd.discount_amt) AS total_discount,
           COUNT(DISTINCT swd.item_sk) AS distinct_items
    FROM sales_with_dim swd
    JOIN date_dim d ON swd.date_sk = d.d_date_sk
    JOIN item i ON swd.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category, swd.channel_type, swd.state
)
SELECT a.d_year,
       a.i_category,
       a.channel_type,
       a.state,
       a.total_quantity,
       a.total_net_profit,
       a.total_discount,
       a.distinct_items,
       RANK() OVER (PARTITION BY a.d_year, a.channel_type ORDER BY a.total_net_profit DESC) AS profit_rank,
       a.total_net_profit - LAG(a.total_net_profit) OVER (PARTITION BY a.channel_type, a.i_category, a.state ORDER BY a.d_year) AS profit_change,
       CASE WHEN LAG(a.total_net_profit) OVER (PARTITION BY a.channel_type, a.i_category, a.state ORDER BY a.d_year) = 0 THEN NULL
            ELSE (a.total_net_profit - LAG(a.total_net_profit) OVER (PARTITION BY a.channel_type, a.i_category, a.state ORDER BY a.d_year))
                 / LAG(a.total_net_profit) OVER (PARTITION BY a.channel_type, a.i_category, a.state ORDER BY a.d_year) * 100
       END AS profit_change_pct
FROM aggregated a
ORDER BY a.d_year, a.channel_type, profit_rank
LIMIT 200
