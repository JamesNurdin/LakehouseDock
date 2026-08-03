WITH high_quantity_ship_modes AS (
    SELECT DISTINCT ws_ship_mode_sk
    FROM web_sales
    WHERE ws_quantity > 10
),
low_quantity_ship_modes AS (
    SELECT DISTINCT ws_ship_mode_sk
    FROM web_sales
    WHERE ws_quantity < 5
),
eligible_ship_modes AS (
    SELECT sm_ship_mode_sk, sm_ship_mode_id, sm_type
    FROM ship_mode
    WHERE sm_ship_mode_sk IN (SELECT ws_ship_mode_sk FROM high_quantity_ship_modes)
      AND sm_ship_mode_sk NOT IN (
          SELECT ws_ship_mode_sk FROM high_quantity_ship_modes
          EXCEPT
          SELECT ws_ship_mode_sk FROM low_quantity_ship_modes
      )
),
ws_with_arrays AS (
    SELECT ws.*, ARRAY[ws.ws_ship_mode_sk, ws.ws_promo_sk] AS ks_array
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),
unnested_keys AS (
    SELECT ws.ws_order_number,
           ws.ws_sold_date_sk,
           ws.ws_ship_mode_sk,
           ws.ws_promo_sk,
           k AS key_val,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY k) AS rn
    FROM ws_with_arrays ws
    CROSS JOIN UNNEST(ws.ks_array) AS t(k)
),
joined_data AS (
    SELECT d.d_year,
           cs.cc_market_manager,
           p.p_channel_tv,
           sm.sm_type,
           uk.key_val,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM unnested_keys uk
    JOIN web_sales ws ON uk.ws_order_number = ws.ws_order_number
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN eligible_ship_modes sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cs ON cs.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE p.p_channel_tv = 'Y'
      AND cs.cc_market_manager = 'Ronald Somerville'
      AND d.d_month_seq BETWEEN 1200 AND 1210
      AND uk.key_val = ws.ws_ship_mode_sk
)
SELECT d_year,
       cc_market_manager,
       p_channel_tv,
       sm_type,
       profit_category,
       key_val,
       SUM(ws_ext_sales_price) AS total_sales,
       SUM(ws_net_profit) AS total_profit,
       RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM joined_data
GROUP BY d_year, cc_market_manager, p_channel_tv, sm_type, profit_category, key_val
ORDER BY d_year, profit_rank
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
