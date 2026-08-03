WITH sales_joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        ss.ss_net_profit,
        ws.ws_net_paid,
        d.d_year,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        p.p_channel_event,
        cc.cc_state,
        r.r_reason_desc,
        sr.sr_return_quantity,
        ws.ws_ext_wholesale_cost
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 80000
      AND p.p_channel_event = 'N'
      AND cc.cc_state = 'CA'
      AND ws.ws_ext_wholesale_cost > 5000
)
SELECT
    d_year,
    ib_income_band_sk,
    p_promo_name,
    SUM(cs_net_paid) AS total_cs_net_paid,
    SUM(ss_net_profit) AS total_ss_net_profit,
    SUM(ws_net_paid) AS total_ws_net_paid,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    COUNT(*) AS rows_cnt
FROM sales_joined
GROUP BY GROUPING SETS (
    (d_year, ib_income_band_sk, p_promo_name),
    (d_year, ib_income_band_sk),
    (p_promo_name),
    ()
)
ORDER BY total_cs_net_paid DESC
LIMIT 100
