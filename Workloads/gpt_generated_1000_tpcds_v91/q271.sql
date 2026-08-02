WITH raw_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        t.t_hour,
        ca.ca_state,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        p.p_channel_email,
        p.p_discount_active,
        s.s_store_name,
        s.s_state AS store_state,
        s.s_geography_class,
        ws.web_name,
        ws.web_state
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND s.s_geography_class = 'Unknown'
      AND p.p_channel_email = 'Y'
      AND p.p_discount_active = 'Y'
),
distinct_sales AS (
    SELECT DISTINCT *
    FROM raw_sales
),
aggregated AS (
    SELECT
        d_year,
        s_store_name,
        ca_state,
        p_promo_name,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss_ticket_number) AS unique_tickets,
        CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM distinct_sales
    GROUP BY
        d_year,
        s_store_name,
        ca_state,
        p_promo_name
)
SELECT
    d_year,
    s_store_name,
    ca_state,
    p_promo_name,
    total_sales,
    avg_profit,
    unique_tickets,
    profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_year
FROM aggregated
ORDER BY d_year, total_sales DESC
LIMIT 100
