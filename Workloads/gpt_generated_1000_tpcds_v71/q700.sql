WITH joined_data AS (
    SELECT
        c.c_customer_id,
        ss.ss_ticket_number,
        ws.ws_order_number,
        ca.ca_city,
        i.i_item_id,
        i.i_current_price,
        d_store.d_year AS store_year,
        d_web.d_year AS web_year,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        wr.wr_net_loss,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        web.web_name,
        web.web_manager
    FROM store_sales ss
    JOIN date_dim d_store ON ss.ss_sold_date_sk = d_store.d_date_sk
    JOIN time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_web ON ws.ws_sold_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib ON hd2.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_store.d_date_sk
    WHERE d_store.d_year = 2000
      AND ib.ib_lower_bound >= 80000
      AND web.web_manager = 'Jason Silva'
)
SELECT
    c_customer_id,
    web_name,
    ib_lower_bound,
    ib_upper_bound,
    total_profit,
    store_txn_cnt,
    web_txn_cnt,
    total_return_loss,
    profit_rank
FROM (
    SELECT
        c_customer_id,
        web_name,
        ib_lower_bound,
        ib_upper_bound,
        SUM(store_net_profit + COALESCE(web_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws_order_number) AS web_txn_cnt,
        SUM(COALESCE(wr_net_loss, 0)) AS total_return_loss,
        RANK() OVER (ORDER BY SUM(store_net_profit + COALESCE(web_net_profit, 0)) DESC) AS profit_rank
    FROM joined_data
    GROUP BY
        c_customer_id,
        web_name,
        ib_lower_bound,
        ib_upper_bound
) agg
WHERE total_profit > 1000
ORDER BY total_profit DESC
LIMIT 100
