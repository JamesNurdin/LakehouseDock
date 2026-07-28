WITH ws_agg AS (
        SELECT
            ws_promo_sk,
            ws_sold_date_sk,
            ws_order_number,
            ws_bill_hdemo_sk,
            sum(ws_net_profit) AS total_profit,
            count(*) AS sales_cnt
        FROM web_sales
        WHERE ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
        )
        GROUP BY ws_promo_sk, ws_sold_date_sk, ws_order_number, ws_bill_hdemo_sk
    ),
    distinct_stores AS (
        SELECT DISTINCT s_store_sk, s_state
        FROM store
        WHERE s_state = 'CA'
    )
SELECT
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    hd.hd_vehicle_count,
    ws_agg.total_profit,
    sum(sr.sr_net_loss) AS total_store_loss,
    sum(wr.wr_net_loss) AS total_web_loss,
    ws_agg.sales_cnt,
    count(DISTINCT s.s_store_sk) AS distinct_store_cnt
FROM ws_agg
JOIN promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN date_dim d ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN household_demographics hd ON ws_agg.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
JOIN catalog_page cp ON d.d_date_sk = cp.cp_end_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN distinct_stores s ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_returns wr ON wr.wr_order_number = ws_agg.ws_order_number
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
WHERE
    d.d_year = 2001
    AND cc.cc_tax_percentage > 0.05
    AND p.p_channel_demo = 'N'
    AND hd.hd_vehicle_count > 1
GROUP BY
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    hd.hd_vehicle_count,
    ws_agg.total_profit,
    ws_agg.sales_cnt
ORDER BY total_store_loss DESC
LIMIT 100
