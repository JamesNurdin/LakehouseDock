WITH base_data AS (
    SELECT
        s.s_store_name,
        d.d_year,
        ss.ss_net_profit        AS ss_net_profit,
        ss.ss_ext_sales_price   AS ss_ext_sales_price,
        ws.ws_net_profit        AS ws_net_profit,
        sr.sr_return_amt,
        wr.wr_return_amt,
        i.i_item_sk,
        i.i_brand,
        ib.ib_upper_bound,
        t.t_hour,
        r.r_reason_desc,
        wsite.web_country
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 1911
      AND i.i_brand = 'Brand#23'
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound <= 50000
      AND t.t_hour BETWEEN 9 AND 17
      AND wsite.web_country = 'USA'
      AND r.r_reason_desc = 'Promotion'
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_date_sk = d.d_date_sk
              AND inv.inv_quantity_on_hand > 0
        )
)
SELECT DISTINCT
    s_store_name,
    d_year,
    SUM(ss_net_profit)       AS total_store_net_profit,
    SUM(ss_ext_sales_price)  AS total_store_sales,
    SUM(ws_net_profit)       AS total_web_net_profit,
    COUNT(*)                 AS transaction_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
FROM base_data
GROUP BY s_store_name, d_year
ORDER BY profit_rank, s_store_name
LIMIT 100
