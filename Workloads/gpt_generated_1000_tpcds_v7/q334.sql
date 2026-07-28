WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_returns sr         ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory i              ON i.inv_date_sk = d.d_date_sk
    JOIN web_sales ws             ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr           ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site wsite           ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 16
      AND sm.sm_type = 'AIR'
      AND s.s_state = 'CA'
      AND cs.cs_net_profit > 0
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_state, p.p_promo_id
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    s_state,
    p_promo_id,
    total_net_profit,
    avg_quantity,
    total_inventory,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_profit DESC) AS rn_state,
    RANK()        OVER (ORDER BY total_net_profit DESC)          AS overall_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100
