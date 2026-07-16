SELECT
    s.s_state,
    s.s_city,
    cd.cd_gender,
    cd.cd_marital_status,
    p.p_channel_tv,
    year(d_sold.d_date) AS sale_year,
    quarter(d_sold.d_date) AS sale_quarter,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS profit_margin,
    CASE
        WHEN d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date THEN 'During Promo'
        ELSE 'Outside Promo'
    END AS promo_period_flag
FROM store_sales ss
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND d_store_closed.d_date <= d_sold.d_date
GROUP BY
    s.s_state,
    s.s_city,
    cd.cd_gender,
    cd.cd_marital_status,
    p.p_channel_tv,
    year(d_sold.d_date),
    quarter(d_sold.d_date),
    CASE
        WHEN d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date THEN 'During Promo'
        ELSE 'Outside Promo'
    END
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
