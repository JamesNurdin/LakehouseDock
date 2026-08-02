WITH store_agg AS (
    SELECT
        d_sales.d_year AS year,
        d_sales.d_month_seq AS month_seq,
        COALESCE(i_ss.i_category, i_sr.i_category) AS category,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amt,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_sales
        ON ss.ss_sold_time_sk = t_sales.t_time_sk
    LEFT JOIN time_dim t_ret
        ON sr.sr_return_time_sk = t_ret.t_time_sk
    LEFT JOIN item i_ss
        ON ss.ss_item_sk = i_ss.i_item_sk
    LEFT JOIN item i_sr
        ON sr.sr_item_sk = i_sr.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    WHERE d_sales.d_year = 2001
      AND t_sales.t_hour = 12
      AND COALESCE(i_ss.i_brand, i_sr.i_brand) = 'BrandX'
      AND COALESCE(cd_ss.cd_gender, cd_sr.cd_gender) = 'F'
      AND p.p_channel_demo = 'N'
      AND d_sales.d_holiday = 'N'
    GROUP BY d_sales.d_year, d_sales.d_month_seq, COALESCE(i_ss.i_category, i_sr.i_category)
),
web_agg AS (
    SELECT
        d_ws.d_year AS year,
        d_ws.d_month_seq AS month_seq,
        i_ws.i_category AS category,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amt,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN item i_ws
        ON ws.ws_item_sk = i_ws.i_item_sk
    LEFT JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    WHERE d_ws.d_year = 2001
      AND t_ws.t_hour = 12
      AND i_ws.i_brand = 'BrandX'
      AND cd_bill.cd_gender = 'F'
      AND p_ws.p_channel_demo = 'N'
      AND sm.sm_contract = 'I3uCelXtjP'
    GROUP BY d_ws.d_year, d_ws.d_month_seq, i_ws.i_category
)
SELECT
    COALESCE(sa.year, wa.year) AS year,
    COALESCE(sa.month_seq, wa.month_seq) AS month_seq,
    COALESCE(sa.category, wa.category) AS category,
    COALESCE(sa.store_net_paid, 0) AS store_net_paid,
    COALESCE(wa.web_net_paid, 0) AS web_net_paid,
    COALESCE(sa.store_return_amt, 0) AS store_return_amt,
    COALESCE(wa.web_return_amt, 0) AS web_return_amt,
    (COALESCE(sa.store_net_paid, 0) - COALESCE(sa.store_return_amt, 0) +
     COALESCE(wa.web_net_paid, 0) - COALESCE(wa.web_return_amt, 0)) AS total_net_amount,
    SUM(
        COALESCE(sa.store_net_paid, 0) - COALESCE(sa.store_return_amt, 0) +
        COALESCE(wa.web_net_paid, 0) - COALESCE(wa.web_return_amt, 0)
    ) OVER (PARTITION BY COALESCE(sa.category, wa.category)
            ORDER BY COALESCE(sa.year, wa.year), COALESCE(sa.month_seq, wa.month_seq)
           ) AS running_total_by_category
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.year = wa.year
   AND sa.month_seq = wa.month_seq
   AND sa.category = wa.category
ORDER BY year, month_seq
LIMIT 100
