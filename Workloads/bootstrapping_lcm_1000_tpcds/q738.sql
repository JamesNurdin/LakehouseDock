SELECT
    ds.d_year,
    ds.d_month_seq,
    ds.d_weekend,
    s.s_state,
    s.s_city,
    s.s_market_desc,
    p.p_promo_name,
    p.p_channel_email,
    p.p_discount_active,
    p.p_cost,
    dsp.d_date               AS promo_start_date,
    dpe.d_date               AS promo_end_date,
    dsc.d_date               AS store_closed_date,
    ws.web_name,
    ws.web_state,
    dwc.d_date               AS web_close_date,
    SUM(ss.ss_ext_sales_price)  AS total_ext_sales,
    SUM(ss.ss_ext_discount_amt) AS total_ext_discount,
    SUM(ss.ss_net_profit)       AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
    AVG(ss.ss_sales_price)      AS avg_sales_price,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) <> 0
        THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
        ELSE NULL
    END                         AS profit_margin
FROM store_sales ss
JOIN date_dim ds   ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN store s       ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p   ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim dsp  ON p.p_start_date_sk = dsp.d_date_sk
JOIN date_dim dpe  ON p.p_end_date_sk = dpe.d_date_sk
JOIN date_dim dsc  ON s.s_closed_date_sk = dsc.d_date_sk
JOIN web_site ws   ON ws.web_open_date_sk = ds.d_date_sk
JOIN date_dim dwc  ON ws.web_close_date_sk = dwc.d_date_sk
GROUP BY
    ds.d_year,
    ds.d_month_seq,
    ds.d_weekend,
    s.s_state,
    s.s_city,
    s.s_market_desc,
    p.p_promo_name,
    p.p_channel_email,
    p.p_discount_active,
    p.p_cost,
    dsp.d_date,
    dpe.d_date,
    dsc.d_date,
    ws.web_name,
    ws.web_state,
    dwc.d_date
ORDER BY ds.d_year DESC, total_ext_sales DESC
LIMIT 100
