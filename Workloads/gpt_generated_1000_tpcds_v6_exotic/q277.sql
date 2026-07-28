WITH joined_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        AVG(ib.ib_lower_bound) AS avg_income_lower,
        AVG(cp.cp_catalog_page_number) AS avg_catalog_page_num
    FROM date_dim d
    JOIN store_sales ss               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s                       ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p                  ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t                   ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd     ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib               ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory i                  ON i.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp              ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_sales ws                 ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr               ON wr.wr_returned_date_sk = d.d_date_sk
                                         AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND p.p_channel_radio = 'N'
    GROUP BY s.s_store_id, s.s_state, d.d_year, d.d_month_seq
)
SELECT
    ja.s_store_id,
    ja.s_state,
    ja.d_year,
    ja.d_month_seq,
    ja.store_sales_profit,
    ja.web_sales_profit,
    ja.total_inventory,
    ja.avg_income_lower,
    ja.avg_catalog_page_num,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2 WHERE ib2.ib_lower_bound > 50000) AS max_income_upper_gt_50k,
    RANK() OVER (PARTITION BY ja.d_year ORDER BY (ja.store_sales_profit + ja.web_sales_profit) DESC) AS profit_rank,
    (ja.store_sales_profit + ja.web_sales_profit) AS total_profit
FROM joined_agg ja
ORDER BY profit_rank, total_profit DESC
LIMIT 100
