WITH brand_year_profit AS (
    SELECT
        i.i_brand AS brand,
        d_sales.d_year AS year,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cr.cr_net_loss) AS return_net_loss,
        COUNT(*) AS transaction_cnt,
        CASE WHEN SUM(ss.ss_net_profit) > 50000 THEN 1 ELSE 0 END AS high_store_flag
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales
      ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p_ss
      ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN catalog_sales cs
      ON cs.cs_item_sk = i.i_item_sk
     AND cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p_cs
      ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN ship_mode sm_cs
      ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs
      ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p_ws
      ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse w_ws
      ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d_sales.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND hd.hd_vehicle_count >= 2
      AND p_ws.p_discount_active = 'Y'
      AND ss.ss_quantity > 0
    GROUP BY i.i_brand, d_sales.d_year
)
SELECT
    brand,
    AVG(total_yearly_net_profit) AS avg_yearly_net_profit,
    MAX(total_yearly_net_profit) AS max_yearly_net_profit,
    CASE WHEN AVG(total_yearly_net_profit) > 100000 THEN 'HIGH_AVG' ELSE 'LOW_AVG' END AS avg_profit_category,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = brand) AS avg_item_price
FROM (
    SELECT
        brand,
        year,
        (store_net_profit + catalog_net_profit + web_net_profit) - COALESCE(return_net_loss, 0) AS total_yearly_net_profit,
        (store_net_profit + catalog_net_profit + web_net_profit) AS total_sales_profit,
        return_net_loss,
        high_store_flag,
        transaction_cnt
    FROM brand_year_profit
) yr
WHERE total_yearly_net_profit > 50000
GROUP BY brand
ORDER BY avg_yearly_net_profit DESC
LIMIT 100
