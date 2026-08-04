WITH sales_raw AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price                     AS catalog_sales_price,
        cs.cs_net_profit                         AS catalog_net_profit,
        d_sold.d_year,
        d_sold.d_quarter_seq,
        sm.sm_ship_mode_id,
        cd_bill.cd_gender                         AS bill_gender,
        ws.ws_ext_sales_price                    AS web_sales_price,
        ws.ws_net_profit                         AS web_net_profit,
        ws.ws_web_site_sk,
        wr.wr_net_loss,
        -- additional joins for depth (no extra columns selected)
        wsit.web_site_id,
        d_site_open.d_year                         AS site_open_year,
        d_site_close.d_year                        AS site_close_year,
        t_return.t_hour,
        cd_refund.cd_gender                       AS refund_gender,
        cd_returning.cd_gender                    AS returning_gender
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk               -- join 1
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk               -- join 2
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk              -- join 3
    JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number               -- join 4
    JOIN web_returns wr
        ON cs.cs_order_number = wr.wr_order_number               -- join 5
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk               -- join 6
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk             -- join 7 (second alias of ship_mode)
    JOIN customer_demographics cd_ws_bill
        ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk            -- join 8 (second alias of customer_demographics)
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk                    -- join 9
    JOIN date_dim d_site_open
        ON wsit.web_open_date_sk = d_site_open.d_date_sk           -- join 10 (first date_dim alias for site open)
    JOIN date_dim d_site_close
        ON wsit.web_close_date_sk = d_site_close.d_date_sk         -- join 11 (second date_dim alias for site close)
    JOIN time_dim t_return
        ON wr.wr_returned_time_sk = t_return.t_time_sk            -- join 12
    JOIN customer_demographics cd_refund
        ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk        -- join 13 (third alias of customer_demographics)
    JOIN customer_demographics cd_returning
        ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk    -- join 14 (fourth alias of customer_demographics)
)
SELECT
    d_year,
    d_quarter_seq,
    sm_ship_mode_id,
    bill_gender,
    SUM(catalog_sales_price + web_sales_price) AS total_sales,
    SUM(catalog_net_profit + web_net_profit - wr_net_loss) AS total_profit,
    CASE
        WHEN SUM(catalog_net_profit + web_net_profit - wr_net_loss) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category,
    LAG(SUM(catalog_net_profit + web_net_profit - wr_net_loss)) OVER (
        PARTITION BY sm_ship_mode_id
        ORDER BY d_year, d_quarter_seq
    ) AS prev_total_profit
FROM sales_raw
GROUP BY CUBE (d_year, d_quarter_seq, sm_ship_mode_id, bill_gender)
ORDER BY d_year DESC NULLS LAST, total_profit DESC NULLS LAST
