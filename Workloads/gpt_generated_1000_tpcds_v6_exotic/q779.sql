WITH sales_totals AS (
    SELECT
        ss.ss_sold_date_sk,
        d_sales.d_date,
        d_sales.d_year,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_manager_id,
        ss.ss_net_profit,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_date_sk,
        ss.ss_quantity,
        ws.ws_quantity
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
        AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_category = 'Sports'
      AND ss.ss_net_profit > 0
)
SELECT
    d_sales.d_date,
    d_sales.d_year,
    i.i_product_name,
    i.i_manager_id,
    sm.sm_type,
    ws_site.web_name,
    inv.inv_quantity_on_hand,
    st.ss_net_profit,
    st.ws_net_profit,
    (st.ss_net_profit + st.ws_net_profit) AS total_profit,
    CASE
        WHEN (st.ss_net_profit + st.ws_net_profit) > 5000 THEN 'HIGH'
        WHEN (st.ss_net_profit + st.ws_net_profit) > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_returned_date_sk = d_sales.d_date_sk
    ) AS return_count,
    DENSE_RANK() OVER (PARTITION BY d_sales.d_year ORDER BY (st.ss_net_profit + st.ws_net_profit) DESC) AS profit_rank
FROM sales_totals st
JOIN date_dim d_sales
    ON st.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON st.i_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = st.ss_sold_date_sk
   AND inv.inv_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON st.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws_site
    ON st.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_ship
    ON st.ws_ship_date_sk = d_ship.d_date_sk
WHERE sm.sm_type = 'AIR'
  AND inv.inv_quantity_on_hand > 0
  AND ws_site.web_state = 'CA'
ORDER BY total_profit DESC
LIMIT 100
