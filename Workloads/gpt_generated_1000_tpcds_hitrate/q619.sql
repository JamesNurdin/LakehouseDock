WITH filtered AS (
   SELECT
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_wholesale_cost,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ps.p_promo_name,
        ps.p_channel_press,
        ps.p_purpose,
        sm.sm_type,
        sm.sm_carrier,
        wsite.web_state,
        wsite.web_county,
        ARRAY[ws.ws_quantity, CAST(ws.ws_wholesale_cost AS double)] AS qty_cost_arr
   FROM tpcds.web_sales ws
   JOIN tpcds.promotion ps       ON ws.ws_promo_sk   = ps.p_promo_sk
   JOIN tpcds.ship_mode sm       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.web_site wsite     ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE ps.p_channel_press = 'N'
     AND ps.p_purpose        = 'Unknown'
     AND sm.sm_type          = 'AIR'
     AND wsite.web_county    = 'Fairfield County'
     AND ws.ws_ext_tax       > 10
     AND ws.ws_wholesale_cost < 80
     AND ws.ws_net_profit    > 0
),
exploded AS (
   SELECT
        f.*, 
        v.value      AS metric_val,
        CASE v.ordinality WHEN 1 THEN 'quantity' ELSE 'wholesale_cost' END AS metric_name
   FROM filtered f
   CROSS JOIN UNNEST(f.qty_cost_arr) WITH ORDINALITY AS v(value, ordinality)
)
SELECT
    state,
    promo_name,
    metric_name,
    SUM(metric_val)            AS metric_sum,
    SUM(total_net_profit)      AS total_net_profit,
    SUM(total_sales)           AS total_sales,
    RANK()   OVER (PARTITION BY state ORDER BY SUM(total_net_profit) DESC) AS state_profit_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(total_net_profit) DESC)           AS overall_rank
FROM (
   SELECT
        e.web_state        AS state,
        e.p_promo_name     AS promo_name,
        e.metric_name,
        e.metric_val,
        e.ws_net_profit    AS total_net_profit,
        e.ws_ext_sales_price AS total_sales
   FROM exploded e
) sub
GROUP BY ROLLUP (state, promo_name, metric_name)
ORDER BY state_profit_rank, overall_rank
OFFSET 0
LIMIT 100
