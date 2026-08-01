/*
  Goal: Summarize combined catalog and web sales, returns, and promotion costs by store (limited to California), calculate net profit, rank stores within each state, compare each store's profit to the state average, and present high‑ and low‑profit stores using a UNION. The result is ordered by state and profit rank and limited to the top 100 rows.
*/
WITH agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        SUM(cs.cs_ext_sales_price)                        AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price)                        AS web_sales_amount,
        SUM(sr.sr_return_amt)                            AS store_return_amount,
        SUM(wr.wr_return_amt)                            AS web_return_amount,
        SUM(p_cs.p_cost)                                 AS catalog_promo_cost,
        SUM(p_ws.p_cost)                                 AS web_promo_cost
    FROM time_dim t
    JOIN store_returns sr        ON sr.sr_return_time_sk   = t.t_time_sk
    JOIN store s                 ON sr.sr_store_sk         = s.s_store_sk
    JOIN reason r_sr             ON sr.sr_reason_sk        = r_sr.r_reason_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk   = hd_sr.hd_demo_sk
    JOIN income_band ib_sr       ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    JOIN catalog_sales cs       ON cs.cs_sold_time_sk    = t.t_time_sk
    JOIN call_center cc          ON cs.cs_call_center_sk   = cc.cc_call_center_sk
    JOIN catalog_page cp         ON cs.cs_catalog_page_sk  = cp.cp_catalog_page_sk
    JOIN warehouse w_cs          ON cs.cs_warehouse_sk     = w_cs.w_warehouse_sk
    JOIN promotion p_cs          ON cs.cs_promo_sk         = p_cs.p_promo_sk
    JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
    JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
    JOIN income_band ib_cs_bill  ON hd_cs_bill.hd_income_band_sk = ib_cs_bill.ib_income_band_sk
    JOIN income_band ib_cs_ship  ON hd_cs_ship.hd_income_band_sk = ib_cs_ship.ib_income_band_sk
    JOIN web_sales ws           ON ws.ws_sold_time_sk    = t.t_time_sk
    JOIN warehouse w_ws         ON ws.ws_warehouse_sk    = w_ws.w_warehouse_sk
    JOIN promotion p_ws         ON ws.ws_promo_sk        = p_ws.p_promo_sk
    JOIN web_page wp_ws         ON ws.ws_web_page_sk    = wp_ws.wp_web_page_sk
    JOIN web_site site          ON ws.ws_web_site_sk    = site.web_site_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN income_band ib_ws_bill ON hd_ws_bill.hd_income_band_sk = ib_ws_bill.ib_income_band_sk
    JOIN income_band ib_ws_ship ON hd_ws_ship.hd_income_band_sk = ib_ws_ship.ib_income_band_sk
    JOIN web_returns wr        ON wr.wr_returned_time_sk = t.t_time_sk
                               AND wr.wr_item_sk        = ws.ws_item_sk
                               AND wr.wr_order_number   = ws.ws_order_number
    JOIN web_page wp_wr        ON wr.wr_web_page_sk      = wp_wr.wp_web_page_sk
    JOIN reason r_wr           ON wr.wr_reason_sk        = r_wr.r_reason_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN income_band ib_wr_refunded ON hd_wr_refunded.hd_income_band_sk = ib_wr_refunded.ib_income_band_sk
    JOIN income_band ib_wr_returning ON hd_wr_returning.hd_income_band_sk = ib_wr_returning.ib_income_band_sk
    WHERE s.s_state = 'CA'
      AND cc.cc_class = 'Class A'
      AND cp.cp_type = 'Online'
      AND p_cs.p_response_target > 0
      AND t.t_hour BETWEEN 9 AND 17
      AND ib_cs_bill.ib_lower_bound >= 50000
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, t.t_hour
),
agg_summary AS (
    SELECT
        a.s_store_sk,
        a.s_store_name,
        a.s_state,
        SUM(a.catalog_sales_amount + a.web_sales_amount)       AS total_sales,
        SUM(a.store_return_amount + a.web_return_amount)       AS total_returns,
        SUM(a.catalog_promo_cost + a.web_promo_cost)           AS total_promo_cost,
        (SUM(a.catalog_sales_amount + a.web_sales_amount) -
         SUM(a.store_return_amount + a.web_return_amount) -
         SUM(a.catalog_promo_cost + a.web_promo_cost))       AS net_profit
    FROM agg a
    GROUP BY a.s_store_sk, a.s_store_name, a.s_state
    HAVING SUM(a.catalog_sales_amount + a.web_sales_amount) > 50000
)
SELECT
    s_store_sk,
    s_store_name,
    s_state,
    total_sales,
    total_returns,
    total_promo_cost,
    net_profit,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY net_profit DESC) AS profit_rank,
    (SELECT AVG(net_profit) FROM agg_summary inner_sum WHERE inner_sum.s_state = outer_sum.s_state) AS avg_state_profit,
    (SELECT MAX(total_sales) FROM agg_summary max_sum WHERE max_sum.s_state = outer_sum.s_state)   AS max_state_sales
FROM agg_summary outer_sum
WHERE net_profit > (SELECT AVG(net_profit) FROM agg_summary)
UNION ALL
SELECT
    s_store_sk,
    s_store_name,
    s_state,
    total_sales,
    total_returns,
    total_promo_cost,
    net_profit,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY net_profit DESC) AS profit_rank,
    (SELECT AVG(net_profit) FROM agg_summary inner_sum WHERE inner_sum.s_state = outer_sum.s_state) AS avg_state_profit,
    (SELECT MAX(total_sales) FROM agg_summary max_sum WHERE max_sum.s_state = outer_sum.s_state)   AS max_state_sales
FROM agg_summary outer_sum
WHERE net_profit <= (SELECT AVG(net_profit) FROM agg_summary)
ORDER BY s_state, profit_rank
LIMIT 100
