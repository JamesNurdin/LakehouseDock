WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_net_profit,
        d.d_year,
        t.t_hour,
        i.i_brand,
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        w.w_state,
        sm.sm_type,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
)
SELECT
    d_year,
    w_state,
    i_brand,
    cd_gender,
    hd_buy_potential,
    sm_type,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(store_net_paid) AS total_store_sales,
    SUM(web_net_paid) AS total_web_sales,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    MIN(cs_net_paid) AS min_catalog_sale,
    MAX(cs_net_paid) AS max_catalog_sale,
    AVG(ib_lower_bound) AS avg_income_lower
FROM base
WHERE d_year = 2001
  AND i_brand = 'Brand#12'
  AND cd_credit_rating = 'Low Risk'
  AND ib_lower_bound >= 50000
  AND w_state = 'NY'
  AND EXISTS (
        SELECT 1 FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = base.cs_item_sk
          AND cs2.cs_net_profit > 1000
      )
GROUP BY d_year, w_state, i_brand, cd_gender, hd_buy_potential, sm_type
ORDER BY total_catalog_sales DESC
LIMIT 100
